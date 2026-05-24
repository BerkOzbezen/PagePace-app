from datetime import datetime
from typing import Annotated, Any

from urllib.parse import quote

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query, status
from google.cloud import firestore
from pydantic import BaseModel, Field

from app.core.deps import get_uid
from app.core.firebase import db
from app.core.utils import book_to_api, doc_to_dict, to_datetime, utc_now
from app.services.pace_service import build_pace_response

router = APIRouter(prefix="/books", tags=["books"])


class BookCreate(BaseModel):
    title: str = Field(..., min_length=1)
    total_pages: int = Field(..., gt=0)
    cover_url: str | None = None
    isbn: str | None = None
    target_date: datetime | None = None


class BookUpdate(BaseModel):
    title: str | None = Field(None, min_length=1)
    total_pages: int | None = Field(None, gt=0)
    current_page: int | None = Field(None, ge=0)
    cover_url: str | None = None
    isbn: str | None = None
    status: str | None = None
    target_date: datetime | None = None


def _books_ref(db: firestore.Client, uid: str):
    return db.collection("users").document(uid).collection("books")


def _get_book_or_404(db: firestore.Client, uid: str, book_id: str) -> dict[str, Any]:
    doc = _books_ref(db, uid).document(book_id).get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kitap bulunamadı")
    return doc_to_dict(doc)


@router.get("")
async def list_books(uid: Annotated[str, Depends(get_uid)]):
    books = [
        book_to_api(doc_to_dict(doc))
        for doc in _books_ref(db, uid).stream()
    ]
    return {"books": books}


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_book(
    body: BookCreate,
    uid: Annotated[str, Depends(get_uid)],
):
    now = utc_now()
    payload: dict[str, Any] = {
        "title": body.title,
        "totalPages": body.total_pages,
        "currentPage": 0,
        "coverUrl": body.cover_url,
        "isbn": body.isbn,
        "status": "reading",
        "targetDate": body.target_date,
        "addedAt": now,
        "completedAt": None,
    }
    _, ref = _books_ref(db, uid).add(payload)
    created = {**payload, "id": ref.id}
    return book_to_api(created)


@router.get("/search")
async def search_books(
    uid: Annotated[str, Depends(get_uid)],
    isbn: str | None = Query(None, min_length=1),
    q: str | None = Query(None, min_length=1),
):
    _ = uid
    if isbn:
        return await _search_by_isbn(isbn)
    if q:
        return await _search_by_title(q)
    raise HTTPException(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        detail="isbn veya q parametresi gerekli",
    )


def _positive_int(value: Any) -> int | None:
    if isinstance(value, int) and value > 0:
        return value
    if isinstance(value, float) and value > 0:
        return int(value)
    return None


async def _fetch_pages_by_isbn(client: httpx.AsyncClient, isbn: str) -> int | None:
    normalized = isbn.replace("-", "").replace(" ", "").strip()
    if not normalized:
        return None
    try:
        response = await client.get(
            f"https://openlibrary.org/isbn/{normalized}.json",
            timeout=10.0,
        )
        if response.status_code != 200:
            return None
        return _positive_int(response.json().get("number_of_pages"))
    except httpx.HTTPError:
        return None


async def _search_by_isbn(isbn: str) -> dict[str, Any]:
    url = (
        "https://openlibrary.org/api/books"
        f"?bibkeys=ISBN:{isbn}&format=json&jscmd=data"
    )
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(url)
        response.raise_for_status()
        data = response.json()

    key = f"ISBN:{isbn}"
    book_data = data.get(key)
    if not book_data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kitap bulunamadı")

    cover_url = None
    covers = book_data.get("cover") or {}
    cover_url = covers.get("medium") or covers.get("large") or covers.get("small")
    if not cover_url:
        cover_url = f"https://covers.openlibrary.org/b/isbn/{isbn}-M.jpg"

    total_pages = _positive_int(book_data.get("number_of_pages"))

    return {
        "title": book_data.get("title"),
        "cover_url": cover_url,
        "isbn": isbn,
        "total_pages": total_pages,
    }


async def _search_by_title(q: str) -> dict[str, Any]:
    url = f"https://openlibrary.org/search.json?title={quote(q)}&limit=5"
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(url)
        response.raise_for_status()
        data = response.json()

        docs = data.get("docs") or []
        results: list[dict[str, Any]] = []
        for doc in docs[:5]:
            cover_i = doc.get("cover_i")
            cover_url = (
                f"https://covers.openlibrary.org/b/id/{cover_i}-M.jpg" if cover_i else None
            )
            author_names = doc.get("author_name") or []
            isbn_list = doc.get("isbn") or []
            isbn = isbn_list[0] if isbn_list else None
            total_pages = _positive_int(doc.get("number_of_pages_median"))
            if total_pages is None and isbn:
                total_pages = await _fetch_pages_by_isbn(client, isbn)

            results.append(
                {
                    "title": doc.get("title"),
                    "author_name": author_names[0] if author_names else None,
                    "total_pages": total_pages,
                    "cover_url": cover_url,
                    "isbn": isbn,
                }
            )

    return {"results": results}


@router.get("/{book_id}")
async def get_book(
    book_id: str,
    uid: Annotated[str, Depends(get_uid)],
):
    return book_to_api(_get_book_or_404(db, uid, book_id))


@router.get("/{book_id}/pace")
async def get_book_pace(
    book_id: str,
    uid: Annotated[str, Depends(get_uid)],
):
    book = _get_book_or_404(db, uid, book_id)

    sessions_ref = (
        _books_ref(db, uid).document(book_id).collection("sessions")
    )
    sessions = [doc.to_dict() or {} for doc in sessions_ref.stream()]

    def sort_key(s: dict[str, Any]) -> datetime:
        ended = to_datetime(s.get("endedAt", s.get("ended_at")))
        return ended or datetime.min.replace(tzinfo=utc_now().tzinfo)

    sessions.sort(key=sort_key, reverse=True)
    recent = sessions[:5]

    if len(recent) < 2:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Hız hesabı için en az 2 oturum gerekli",
        )

    return build_pace_response(recent, book)


@router.put("/{book_id}")
async def update_book(
    book_id: str,
    body: BookUpdate,
    uid: Annotated[str, Depends(get_uid)],
):
    ref = _books_ref(db, uid).document(book_id)
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kitap bulunamadı")

    updates: dict[str, Any] = {}
    field_map = {
        "title": "title",
        "total_pages": "totalPages",
        "current_page": "currentPage",
        "cover_url": "coverUrl",
        "isbn": "isbn",
        "status": "status",
        "target_date": "targetDate",
    }
    for api_field, firestore_field in field_map.items():
        value = getattr(body, api_field)
        if value is not None:
            updates[firestore_field] = value

    if not updates:
        return book_to_api(_get_book_or_404(db, uid, book_id))

    if body.status == "completed":
        updates["completedAt"] = utc_now()

    ref.update(updates)
    return book_to_api(_get_book_or_404(db, uid, book_id))


@router.delete("/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_book(
    book_id: str,
    uid: Annotated[str, Depends(get_uid)],
):
    ref = _books_ref(db, uid).document(book_id)
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kitap bulunamadı")
    ref.delete()
