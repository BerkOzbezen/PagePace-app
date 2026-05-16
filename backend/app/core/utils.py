from datetime import datetime, timezone
from typing import Any

from google.cloud.firestore_v1 import DocumentSnapshot


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def to_datetime(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value
    if hasattr(value, "timestamp"):
        return datetime.fromtimestamp(value.timestamp(), tz=timezone.utc)
    if isinstance(value, str):
        normalized = value.replace("Z", "+00:00")
        try:
            parsed = datetime.fromisoformat(normalized)
        except ValueError:
            return None
        if parsed.tzinfo is None:
            return parsed.replace(tzinfo=timezone.utc)
        return parsed
    return None


def to_date_str(value: Any) -> str | None:
    dt = to_datetime(value)
    if dt is None:
        return None
    return dt.date().isoformat()


def doc_to_dict(doc: DocumentSnapshot, id_field: str = "id") -> dict[str, Any]:
    data = doc.to_dict() or {}
    data[id_field] = doc.id
    return data


def snake_to_camel(snake: str) -> str:
    parts = snake.split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])


def camel_to_snake(name: str) -> str:
    result: list[str] = []
    for char in name:
        if char.isupper() and result:
            result.append("_")
        result.append(char.lower())
    return "".join(result)


def book_to_api(data: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": data.get("id"),
        "title": data.get("title"),
        "total_pages": data.get("totalPages", data.get("total_pages", 0)),
        "current_page": data.get("currentPage", data.get("current_page", 0)),
        "cover_url": data.get("coverUrl", data.get("cover_url")),
        "isbn": data.get("isbn"),
        "status": data.get("status", "reading"),
        "target_date": to_date_str(data.get("targetDate", data.get("target_date"))),
        "added_at": to_datetime(data.get("addedAt", data.get("added_at"))),
        "completed_at": to_datetime(
            data.get("completedAt", data.get("completed_at"))
        ),
    }


def session_to_api(data: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": data.get("id"),
        "book_id": data.get("bookId", data.get("book_id")),
        "start_page": data.get("startPage", data.get("start_page")),
        "end_page": data.get("endPage", data.get("end_page")),
        "duration_seconds": data.get("durationSeconds", data.get("duration_seconds")),
        "started_at": to_datetime(data.get("startedAt", data.get("started_at"))),
        "ended_at": to_datetime(data.get("endedAt", data.get("ended_at"))),
    }


def user_to_api(data: dict[str, Any]) -> dict[str, Any]:
    return {
        "uid": data.get("uid"),
        "display_name": data.get("displayName", data.get("display_name")),
        "email": data.get("email"),
        "avatar_url": data.get("avatarUrl", data.get("avatar_url")),
        "bio": data.get("bio"),
        "is_profile_hidden": data.get(
            "isProfileHidden", data.get("is_profile_hidden", False)
        ),
        "is_premium": data.get("isPremium", data.get("is_premium", False)),
        "created_at": to_datetime(data.get("createdAt", data.get("created_at"))),
    }
