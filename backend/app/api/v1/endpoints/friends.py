from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.core.deps import get_uid
from app.core.firebase import db
from app.core.utils import doc_to_dict, utc_now
from app.services.stats_service import fetch_all_sessions, session_pages, streak_stats

router = APIRouter(prefix="/friends", tags=["friends"])


class FriendRequest(BaseModel):
    email: str


class FriendRequestAction(BaseModel):
    sender_uid: str = Field(..., min_length=1)


def _friends_ref(uid: str):
    return db.collection("users").document(uid).collection("friends")


def _requests_ref(uid: str):
    return db.collection("users").document(uid).collection("friendRequests")


def _user_ref(uid: str):
    return db.collection("users").document(uid)


def _find_user_by_email(email: str):
    normalized = email.strip().lower()
    for doc in db.collection("users").where("email", "==", normalized).limit(1).stream():
        return doc
    return None


def _user_stats(uid: str) -> dict[str, int]:
    sessions = fetch_all_sessions(db, uid)
    streak = streak_stats(sessions)
    total_pages = sum(session_pages(session) for session in sessions)
    return {
        "current_streak": streak["current_streak"],
        "total_pages": total_pages,
    }


def _friend_payload(friend_uid: str) -> dict[str, Any]:
    user_doc = _user_ref(friend_uid).get()
    user_data = user_doc.to_dict() or {} if user_doc.exists else {}
    stats = _user_stats(friend_uid)
    return {
        "uid": friend_uid,
        "display_name": user_data.get("displayName"),
        "email": user_data.get("email"),
        "current_streak": stats["current_streak"],
        "total_pages": stats["total_pages"],
    }


@router.get("")
async def list_friends(uid: Annotated[str, Depends(get_uid)]):
    friends = [
        _friend_payload(doc.id)
        for doc in _friends_ref(uid).stream()
    ]
    return {"friends": friends}


@router.post("/request", status_code=status.HTTP_201_CREATED)
async def send_friend_request(
    body: FriendRequest,
    uid: Annotated[str, Depends(get_uid)],
):
    target_email = body.email.strip().lower()
    target_doc = _find_user_by_email(target_email)
    if target_doc is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bu e-posta ile kayıtlı kullanıcı bulunamadı",
        )

    target_uid = target_doc.id
    if target_uid == uid:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Kendinize arkadaşlık isteği gönderemezsiniz",
        )

    if _friends_ref(uid).document(target_uid).get().exists:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Bu kullanıcı zaten arkadaşınız",
        )

    if _requests_ref(target_uid).document(uid).get().exists:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Bekleyen arkadaşlık isteği zaten var",
        )

    sender_doc = _user_ref(uid).get()
    sender_data = sender_doc.to_dict() or {} if sender_doc.exists else {}

    payload = {
        "status": "pending",
        "senderUid": uid,
        "senderEmail": sender_data.get("email") or target_email,
        "senderName": sender_data.get("displayName") or sender_data.get("email") or "Kullanıcı",
        "createdAt": utc_now(),
    }
    _requests_ref(target_uid).document(uid).set(payload)
    return {"status": "pending", "target_uid": target_uid}


@router.get("/requests")
async def list_friend_requests(uid: Annotated[str, Depends(get_uid)]):
    requests: list[dict[str, Any]] = []
    for doc in _requests_ref(uid).stream():
        data = doc_to_dict(doc)
        if data.get("status") != "pending":
            continue
        requests.append(
            {
                "sender_uid": doc.id,
                "sender_name": data.get("senderName"),
                "sender_email": data.get("senderEmail"),
                "status": data.get("status"),
                "created_at": data.get("createdAt"),
            }
        )
    return {"requests": requests}


@router.post("/accept")
async def accept_friend_request(
    body: FriendRequestAction,
    uid: Annotated[str, Depends(get_uid)],
):
    sender_uid = body.sender_uid
    request_ref = _requests_ref(uid).document(sender_uid)
    request_doc = request_ref.get()
    if not request_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arkadaşlık isteği bulunamadı",
        )

    data = request_doc.to_dict() or {}
    if data.get("status") != "pending":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="İstek artık beklemede değil",
        )

    now = utc_now()
    request_ref.update({"status": "accepted", "acceptedAt": now})

    _friends_ref(uid).document(sender_uid).set({"addedAt": now})
    _friends_ref(sender_uid).document(uid).set({"addedAt": now})

    return {"status": "accepted", "sender_uid": sender_uid}


@router.post("/reject")
async def reject_friend_request(
    body: FriendRequestAction,
    uid: Annotated[str, Depends(get_uid)],
):
    request_ref = _requests_ref(uid).document(body.sender_uid)
    if not request_ref.get().exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arkadaşlık isteği bulunamadı",
        )
    request_ref.delete()
    return {"status": "rejected", "sender_uid": body.sender_uid}
