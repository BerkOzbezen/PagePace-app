from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.core.deps import get_uid
from app.core.firebase import db
from app.core.utils import doc_to_dict, utc_now
from app.services.stats_service import (
    fetch_all_sessions,
    friend_weekly_pages,
    streak_stats,
)

router = APIRouter(prefix="/friends", tags=["friends"])


class FriendRequestCreate(BaseModel):
    to_user_id: str = Field(..., min_length=1)


class FriendRequestAction(BaseModel):
    action: Literal["accept", "reject"]


def _friendships_ref(db):
    return db.collection("friendships")


def _find_friendship(db, uid: str, other_uid: str) -> dict[str, Any] | None:
    for doc in _friendships_ref(db).stream():
        data = doc.to_dict() or {}
        from_uid = data.get("fromUid")
        to_uid = data.get("toUid")
        if {from_uid, to_uid} == {uid, other_uid}:
            return {**data, "id": doc.id}
    return None


def _active_friendship(db, uid: str, friend_uid: str) -> dict[str, Any] | None:
    friendship = _find_friendship(db, uid, friend_uid)
    if friendship and friendship.get("status") == "active":
        return friendship
    return None


def _friend_uid_from(friendship: dict[str, Any], uid: str) -> str:
    if friendship.get("fromUid") == uid:
        return friendship["toUid"]
    return friendship["fromUid"]


@router.post("/request", status_code=status.HTTP_201_CREATED)
async def send_friend_request(
    body: FriendRequestCreate,
    uid: Annotated[str, Depends(get_uid)],
):
    if body.to_user_id == uid:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Kendinize arkadaşlık isteği gönderemezsiniz",
        )

    target = db.collection("users").document(body.to_user_id).get()
    if not target.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı"
        )

    existing = _find_friendship(db, uid, body.to_user_id)
    if existing:
        status_value = existing.get("status")
        if status_value == "active":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Bu kullanıcı zaten arkadaşınız",
            )
        if status_value == "pending":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Bekleyen arkadaşlık isteği zaten var",
            )

    payload = {
        "fromUid": uid,
        "toUid": body.to_user_id,
        "status": "pending",
        "createdAt": utc_now(),
    }
    _, ref = _friendships_ref(db).add(payload)
    return {"id": ref.id, "status": "pending"}


@router.put("/request/{friendship_id}")
async def respond_friend_request(
    friendship_id: str,
    body: FriendRequestAction,
    uid: Annotated[str, Depends(get_uid)],
):
    ref = _friendships_ref(db).document(friendship_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="İstek bulunamadı"
        )

    data = doc.to_dict() or {}
    if data.get("toUid") != uid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu isteği yanıtlama yetkiniz yok",
        )
    if data.get("status") != "pending":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="İstek artık beklemede değil",
        )

    new_status = "active" if body.action == "accept" else "rejected"
    ref.update({"status": new_status})
    return {"id": friendship_id, "status": new_status}


@router.get("")
async def list_friends(uid: Annotated[str, Depends(get_uid)]):
    friends: list[dict[str, Any]] = []

    for doc in _friendships_ref(db).stream():
        data = doc.to_dict() or {}
        if data.get("status") != "active":
            continue
        if uid not in (data.get("fromUid"), data.get("toUid")):
            continue

        friend_uid = _friend_uid_from(data, uid)
        user_doc = db.collection("users").document(friend_uid).get()
        user_data = user_doc.to_dict() or {} if user_doc.exists else {}
        friends.append(
            {
                "friendship_id": doc.id,
                "uid": friend_uid,
                "display_name": user_data.get("displayName"),
                "avatar_url": user_data.get("avatarUrl"),
            }
        )

    return {"friends": friends}


@router.delete("/{friendship_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_friend(
    friendship_id: str,
    uid: Annotated[str, Depends(get_uid)],
):
    ref = _friendships_ref(db).document(friendship_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Arkadaşlık bulunamadı"
        )

    data = doc.to_dict() or {}
    if uid not in (data.get("fromUid"), data.get("toUid")):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu arkadaşlığı silme yetkiniz yok",
        )
    ref.delete()


@router.get("/{friend_uid}/stats")
async def get_friend_stats(
    friend_uid: str,
    uid: Annotated[str, Depends(get_uid)],
):
    friendship = _active_friendship(db, uid, friend_uid)
    if not friendship:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu kullanıcının istatistiklerini görüntüleme yetkiniz yok",
        )

    friend_doc = db.collection("users").document(friend_uid).get()
    if not friend_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı"
        )
    friend_data = friend_doc.to_dict() or {}
    if friend_data.get("isProfileHidden"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu profil gizli",
        )

    sessions = fetch_all_sessions(db, friend_uid)
    books_ref = db.collection("users").document(friend_uid).collection("books")
    total_books = sum(1 for _ in books_ref.stream())
    streak = streak_stats(sessions)

    return {
        "weekly_pages": friend_weekly_pages(sessions),
        "current_streak": streak["current_streak"],
        "total_books": total_books,
    }
