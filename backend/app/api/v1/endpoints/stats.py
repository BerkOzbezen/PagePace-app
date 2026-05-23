from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.deps import get_uid
from app.core.firebase import db
from app.core.utils import doc_to_dict
from app.services.stats_service import (
    fetch_all_sessions,
    heatmap_stats,
    monthly_stats,
    streak_stats,
    weekly_stats,
    yearly_stats,
)

router = APIRouter(prefix="/stats", tags=["stats"])


def _fetch_books(db, uid: str) -> list[dict]:
    books_ref = db.collection("users").document(uid).collection("books")
    return [doc_to_dict(doc) for doc in books_ref.stream()]


@router.get("/weekly")
async def get_weekly_stats(uid: Annotated[str, Depends(get_uid)]):
    sessions = fetch_all_sessions(db, uid)
    return weekly_stats(sessions)


@router.get("/monthly")
async def get_monthly_stats(uid: Annotated[str, Depends(get_uid)]):
    sessions = fetch_all_sessions(db, uid)
    return monthly_stats(sessions)


@router.get("/yearly")
async def get_yearly_stats(uid: Annotated[str, Depends(get_uid)]):
    sessions = fetch_all_sessions(db, uid)
    books = _fetch_books(db, uid)
    return yearly_stats(sessions, books)


@router.get("/streak")
async def get_streak_stats(uid: Annotated[str, Depends(get_uid)]):
    sessions = fetch_all_sessions(db, uid)
    return streak_stats(sessions)


@router.get("/heatmap")
async def get_heatmap_stats(uid: Annotated[str, Depends(get_uid)]):
    sessions = fetch_all_sessions(db, uid)
    return heatmap_stats(sessions)
