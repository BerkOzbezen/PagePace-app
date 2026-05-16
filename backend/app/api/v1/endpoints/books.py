from datetime import datetime
from typing import Annotated, Any

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query, status
from google.cloud import firestore
from pydantic import BaseModel, Field

from app.core.firebase import get_db, get_current_user
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
async def list_books(uid: Annotated[str, Depends(get_current_user)]):
    db = get_db()
    books = [
        book_to_api(doc_to_dict(doc))
        for doc in _books_ref(db, uid).stream()
    ]
    return {"books": books}


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_book(
    body: BookCreate,
    uid: Annotated[str, Depends(get_current_user)],
):
    db = get_db()
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
async def search_books_by_isbn(
    uid: Annotated[str, Depends(get_current_user)],
    isbn: str = Query(..., min_length=1),
):
    _ = uid
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

    return {
        "title": book_data.get("title"),
        "cover_url": cover_url,
        "isbn": isbn,
    }


@router.get("/{book_id}")
async def get_book(
    book_id: str,
    uid: Annotated[str, Depends(get_current_user)],
):
    db = get_db()
    return book_to_api(_get_book_or_404(db, uid, book_id))


@router.get("/{book_id}/pace")
async def get_book_pace(
    book_id: str,
    uid: Annotated[str, Depends(get_current_user)],
):
    db = get_db()
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
    uid: Annotated[str, Depends(get_current_user)],
):
    db = get_db()
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
    uid: Annotated[str, Depends(get_current_user)],
):
    db = get_db()
    ref = _books_ref(db, uid).document(book_id)
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kitap bulunamadı")
    ref.delete()
