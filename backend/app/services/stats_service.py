from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from typing import Any

from app.core.utils import to_datetime


def fetch_all_sessions(
    db: Any, uid: str, since: datetime | None = None
) -> list[dict[str, Any]]:
    sessions: list[dict[str, Any]] = []
    books_ref = db.collection("users").document(uid).collection("books")
    for book_doc in books_ref.stream():
        query = book_doc.reference.collection("sessions")
        for session_doc in query.stream():
            data = session_doc.to_dict() or {}
            data["id"] = session_doc.id
            data["bookId"] = book_doc.id
            ended = to_datetime(data.get("endedAt", data.get("ended_at")))
            if since is not None and ended is not None and ended < since:
                continue
            sessions.append(data)
    return sessions


def session_pages(session: dict[str, Any]) -> int:
    start = session.get("startPage", session.get("start_page", 0))
    end = session.get("endPage", session.get("end_page", 0))
    return max(0, end - start)


def session_minutes(session: dict[str, Any]) -> float:
    seconds = session.get("durationSeconds", session.get("duration_seconds", 0))
    return max(0, seconds) / 60.0


def weekly_stats(sessions: list[dict[str, Any]], today: date | None = None) -> list[dict]:
    today = today or datetime.now(timezone.utc).date()
    start = today - timedelta(days=6)
    by_date: dict[str, dict[str, float]] = defaultdict(
        lambda: {"total_minutes": 0.0, "pages_read": 0}
    )

    for session in sessions:
        ended = to_datetime(session.get("endedAt", session.get("ended_at")))
        if ended is None:
            continue
        day = ended.date()
        if day < start or day > today:
            continue
        key = day.isoformat()
        by_date[key]["total_minutes"] += session_minutes(session)
        by_date[key]["pages_read"] += session_pages(session)

    result = []
    for i in range(7):
        day = start + timedelta(days=i)
        key = day.isoformat()
        entry = by_date[key]
        result.append(
            {
                "date": key,
                "total_minutes": round(entry["total_minutes"], 1),
                "pages_read": int(entry["pages_read"]),
            }
        )
    return result


def monthly_stats(sessions: list[dict[str, Any]], today: date | None = None) -> list[dict]:
    today = today or datetime.now(timezone.utc).date()
    start = today - timedelta(days=29)
    week_buckets = [
        {"week": w, "total_minutes": 0.0, "pages_read": 0} for w in range(1, 5)
    ]

    for session in sessions:
        ended = to_datetime(session.get("endedAt", session.get("ended_at")))
        if ended is None:
            continue
        day = ended.date()
        if day < start or day > today:
            continue
        days_from_start = (day - start).days
        week_index = min(3, days_from_start // 7)
        week_buckets[week_index]["total_minutes"] += session_minutes(session)
        week_buckets[week_index]["pages_read"] += session_pages(session)

    for bucket in week_buckets:
        bucket["total_minutes"] = round(bucket["total_minutes"], 1)
    return week_buckets


def yearly_stats(
    sessions: list[dict[str, Any]], books: list[dict[str, Any]], today: date | None = None
) -> dict[str, Any]:
    today = today or datetime.now(timezone.utc).date()
    year_start = date(today.year, 1, 1)

    total_pages = 0
    total_minutes = 0.0
    active_days: set[date] = set()

    for session in sessions:
        ended = to_datetime(session.get("endedAt", session.get("ended_at")))
        if ended is None or ended.date() < year_start:
            continue
        total_pages += session_pages(session)
        total_minutes += session_minutes(session)
        active_days.add(ended.date())

    completed_books = sum(
        1
        for book in books
        if book.get("status") == "completed"
        or (
            book.get("currentPage", book.get("current_page", 0))
            >= book.get("totalPages", book.get("total_pages", 0))
            > 0
        )
    )

    days_elapsed = max(1, (today - year_start).days + 1)
    avg_pages = round(total_pages / days_elapsed, 2)

    return {
        "total_books": completed_books,
        "total_pages": total_pages,
        "total_hours": round(total_minutes / 60.0, 2),
        "avg_pages_per_day": avg_pages,
    }


def streak_stats(sessions: list[dict[str, Any]], today: date | None = None) -> dict[str, Any]:
    today = today or datetime.now(timezone.utc).date()
    read_dates: set[date] = set()

    for session in sessions:
        ended = to_datetime(session.get("endedAt", session.get("ended_at")))
        if ended is not None:
            read_dates.add(ended.date())

    if not read_dates:
        return {"current_streak": 0, "longest_streak": 0, "last_read_date": None}

    last_read_date = max(read_dates)
    sorted_dates = sorted(read_dates)

    longest = 1
    current_run = 1
    for i in range(1, len(sorted_dates)):
        if (sorted_dates[i] - sorted_dates[i - 1]).days == 1:
            current_run += 1
            longest = max(longest, current_run)
        else:
            current_run = 1

    current_streak = 0
    cursor = today
    while cursor in read_dates:
        current_streak += 1
        cursor -= timedelta(days=1)

    if current_streak == 0 and today - timedelta(days=1) in read_dates:
        cursor = today - timedelta(days=1)
        while cursor in read_dates:
            current_streak += 1
            cursor -= timedelta(days=1)

    return {
        "current_streak": current_streak,
        "longest_streak": longest,
        "last_read_date": last_read_date.isoformat(),
    }


def heatmap_stats(sessions: list[dict[str, Any]]) -> dict[str, int]:
    buckets = {"morning": 0, "afternoon": 0, "evening": 0, "night": 0}

    for session in sessions:
        started = to_datetime(session.get("startedAt", session.get("started_at")))
        if started is None:
            continue
        hour = started.hour
        if 6 <= hour <= 11:
            buckets["morning"] += 1
        elif 12 <= hour <= 17:
            buckets["afternoon"] += 1
        elif 18 <= hour <= 22:
            buckets["evening"] += 1
        else:
            buckets["night"] += 1

    return buckets


def friend_weekly_pages(sessions: list[dict[str, Any]], today: date | None = None) -> int:
    today = today or datetime.now(timezone.utc).date()
    start = today - timedelta(days=6)
    total = 0
    for session in sessions:
        ended = to_datetime(session.get("endedAt", session.get("ended_at")))
        if ended is None:
            continue
        if start <= ended.date() <= today:
            total += session_pages(session)
    return total
