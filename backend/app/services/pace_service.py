from datetime import date, datetime, timedelta
from math import ceil
from typing import Any

from app.core.utils import to_datetime


def calculate_pace(sessions: list[dict[str, Any]]) -> float:
    total_pages = 0
    total_seconds = 0
    for session in sessions:
        start = session.get("startPage", session.get("start_page", 0))
        end = session.get("endPage", session.get("end_page", 0))
        duration = session.get("durationSeconds", session.get("duration_seconds", 0))
        total_pages += max(0, end - start)
        total_seconds += max(0, duration)

    if total_seconds <= 0:
        return 0.0
    return (total_pages / total_seconds) * 3600


def estimate_finish(
    pace: float, remaining_pages: int, now: datetime | None = None
) -> dict[str, Any]:
    if pace <= 0 or remaining_pages <= 0:
        finish = now or datetime.now()
        return {
            "estimated_hours": 0.0,
            "estimated_finish_date": finish.date().isoformat(),
        }

    estimated_hours = remaining_pages / pace
    finish_dt = (now or datetime.now()) + timedelta(hours=estimated_hours)
    return {
        "estimated_hours": round(estimated_hours, 2),
        "estimated_finish_date": finish_dt.date().isoformat(),
    }


def daily_target(remaining_pages: int, days_left: int) -> int:
    if days_left <= 0:
        return remaining_pages
    return ceil(remaining_pages / days_left)


def build_pace_response(
    sessions: list[dict[str, Any]],
    book: dict[str, Any],
    now: datetime | None = None,
) -> dict[str, Any]:
    now = now or datetime.now()
    pages_per_hour = calculate_pace(sessions)
    total_pages = book.get("totalPages", book.get("total_pages", 0))
    current_page = book.get("currentPage", book.get("current_page", 0))
    remaining_pages = max(0, total_pages - current_page)

    finish = estimate_finish(pages_per_hour, remaining_pages, now)
    daily_target_pages: int | None = None

    target = book.get("targetDate", book.get("target_date"))
    target_dt = to_datetime(target)
    if target_dt is not None:
        days_left = (target_dt.date() - now.date()).days
        if days_left >= 0:
            daily_target_pages = daily_target(remaining_pages, days_left)

    return {
        "pages_per_hour": round(pages_per_hour, 2),
        "remaining_pages": remaining_pages,
        "estimated_hours": finish["estimated_hours"],
        "estimated_finish_date": finish["estimated_finish_date"],
        "daily_target_pages": daily_target_pages,
        "sessions_used": len(sessions),
    }
