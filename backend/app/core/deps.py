from typing import Annotated

from fastapi import Depends, HTTPException

from app.core.firebase import get_current_user


async def get_uid(
    user: Annotated[dict, Depends(get_current_user)],
) -> str:
    uid = user.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Geçersiz veya süresi dolmuş token")
    return uid
