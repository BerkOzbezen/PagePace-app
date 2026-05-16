from datetime import datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from google.cloud import firestore
from pydantic import BaseModel, Field, model_validator

from app.core.firebase import get_db, get_current_user
from app.core.utils import doc_to_dict, session_to_api, to_datetime, utc_now

router = APIRouter(prefix="/sessions", tags=["sessions"])


class SessionCreate(BaseModel):
    book_id: str = Field(..., min_length=1)
    start_page: int = Field(..., ge=0)
    end_page: int = Field(..., ge=0)
    duration_seconds: int = Field(..., gt=0)
    started_at: datetime
    ended_at: datetime

    @model_validator(mode="after")
    def validate_pages(self):
        if self.end_page <= self.start_page:
            raise ValueError("end_page must be greater than start_page")
        return self


def _books_ref(db: firestore.Client, uid: str):
    return db.collection("users").document(uid).collection("books")


def _sessions_ref(db: firestore.Client, uid: str, book_id: str):
    return _books_ref(db, uid).document(book_id).collection("sessions")


def _ensure_book_exists(db: firestore.Client, uid: str, book_id: str) -> None:
    if not _books_ref(db, uid).document(book_id).get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kitap bulunamadı")


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_session(
    body: SessionCreate,
    uid: Annotated[str, Depends(get_current_user)],
):
    db = get_db()
    _ensure_book_exists(db, uid, body.book_id)

    payload: dict[str, Any] = {
        "bookId": body.book_id,
        "userId": uid,
        "startPage": body.start_page,
        "endPage": body.end_page,
        "durationSeconds": body.duration_seconds,
        "startedAt": body.started_at,
        "endedAt": body.ended_at,
    }
    _, ref = _sessions_ref(db, uid, body.book_id).add(payload)

    book_ref = _books_ref(db, uid).document(body.book_id)
    book_updates: dict[str, Any] = {"currentPage": body.end_page}
    book_data = book_ref.get().to_dict() or {}
    total_pages = book_data.get("totalPages", 0)
    if body.end_page >= total_pages > 0:
        book_updates["status"] = "completed"
        book_updates["completedAt"] = utc_now()
    book_ref.update(book_updates)

    created = {**payload, "id": ref.id}
    return session_to_api(created)


@router.get("")
async def list_sessions(
    uid: Annotated[str, Depends(get_current_user)],
    book_id: str = Query(..., min_length=1),
):
    db = get_db()
    _ensure_book_exists(db, uid, book_id)

    sessions = [
        session_to_api(doc_to_dict(doc))
        for doc in _sessions_ref(db, uid, book_id).stream()
    ]
    sessions.sort(
        key=lambda s: to_datetime(s.get("ended_at")) or datetime.min,
        reverse=True,
    )
    return {"sessions": sessions}


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(
    session_id: str,
    uid: Annotated[str, Depends(get_current_user)],
    book_id: str = Query(..., min_length=1),
):
    db = get_db()
    _ensure_book_exists(db, uid, book_id)
    ref = _sessions_ref(db, uid, book_id).document(session_id)
    if not ref.get().exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Oturum bulunamadı"
        )
    ref.delete()
