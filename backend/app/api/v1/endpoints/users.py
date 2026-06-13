from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field

from app.core.deps import get_uid
from app.core.firebase import db
from app.core.utils import doc_to_dict, user_to_api, utc_now

router = APIRouter(prefix="/users", tags=["users"])


class PrivacyUpdate(BaseModel):
    is_profile_hidden: bool


class ProfileCreate(BaseModel):
    display_name: str = Field(..., min_length=1)
    email: str = Field(..., min_length=1)


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
async def get_me(uid: Annotated[str, Depends(get_uid)]):
    return user_to_api(_get_user_or_404(db, uid))


@router.post("/profile", status_code=status.HTTP_201_CREATED)
async def create_profile(
    body: ProfileCreate,
    uid: Annotated[str, Depends(get_uid)],
):
    ref = _user_ref(db, uid)
    payload: dict[str, Any] = {
        "displayName": body.display_name.strip(),
        "email": body.email.strip().lower(),
        "updatedAt": utc_now(),
    }
    if not ref.get().exists:
        payload["createdAt"] = utc_now()
    ref.set(payload, merge=True)
    return user_to_api({**payload, "uid": uid})


@router.get("/search")
async def search_users(
    uid: Annotated[str, Depends(get_uid)],
    username: str = Query(..., min_length=1),
):
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
    uid: Annotated[str, Depends(get_uid)],
):
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
