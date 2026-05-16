from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel

from app.core.firebase import get_db, get_current_user
from app.core.utils import doc_to_dict, user_to_api, utc_now

router = APIRouter(prefix="/users", tags=["users"])


class PrivacyUpdate(BaseModel):
    is_profile_hidden: bool


def _user_ref(db, uid: str):
    return db.collection("users").document(uid)


def _get_user_or_404(db, uid: str) -> dict[str, Any]:
    doc = _user_ref(db, uid).get()
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı"
        )
    data = doc_to_dict(doc, id_field="uid")
    data["uid"] = doc.id
    return data


@router.get("/me")
async def get_me(uid: Annotated[str, Depends(get_current_user)]):
    db = get_db()
    return user_to_api(_get_user_or_404(db, uid))


@router.get("/search")
async def search_users(
    uid: Annotated[str, Depends(get_current_user)],
    username: str = Query(..., min_length=1),
):
    db = get_db()
    query = (
        db.collection("users")
        .where("displayName", ">=", username)
        .where("displayName", "<=", username + "\uf8ff")
        .limit(11)
    )

    results = []
    for doc in query.stream():
        if doc.id == uid:
            continue
        data = doc.to_dict() or {}
        if data.get("isProfileHidden"):
            continue
        results.append(
            {
                "uid": doc.id,
                "display_name": data.get("displayName"),
                "avatar_url": data.get("avatarUrl"),
            }
        )
        if len(results) >= 10:
            break

    return {"users": results}


@router.put("/privacy")
async def update_privacy(
    body: PrivacyUpdate,
    uid: Annotated[str, Depends(get_current_user)],
):
    db = get_db()
    ref = _user_ref(db, uid)
    if not ref.get().exists:
        ref.set(
            {
                "isProfileHidden": body.is_profile_hidden,
                "createdAt": utc_now(),
            }
        )
    else:
        ref.update({"isProfileHidden": body.is_profile_hidden})

    return {"is_profile_hidden": body.is_profile_hidden}
