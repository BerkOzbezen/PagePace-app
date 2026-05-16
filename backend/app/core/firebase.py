from pathlib import Path
from typing import Annotated

import firebase_admin
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth, credentials, firestore

from app.core.config import get_settings

_bearer = HTTPBearer(auto_error=False)
_db: firestore.Client | None = None


def _resolve_credentials_path() -> Path:
    settings = get_settings()
    path = Path(settings.FIREBASE_CREDENTIALS_PATH)
    if not path.is_absolute():
        backend_root = Path(__file__).resolve().parents[2]
        path = backend_root / path
    return path


def init_firebase() -> firestore.Client:
    global _db
    if firebase_admin._apps:
        _db = firestore.client()
        return _db

    cred_path = _resolve_credentials_path()
    if not cred_path.exists():
        raise FileNotFoundError(f"Firebase credentials not found: {cred_path}")

    cred = credentials.Certificate(str(cred_path))
    firebase_admin.initialize_app(cred)
    _db = firestore.client()
    return _db


def get_db() -> firestore.Client:
    if _db is None:
        return init_firebase()
    return _db


# Firestore client (initialized via init_firebase on app startup)
db: firestore.Client | None = None


def get_firestore() -> firestore.Client:
    return get_db()


async def get_current_user(
    credentials_header: Annotated[
        HTTPAuthorizationCredentials | None, Depends(_bearer)
    ],
) -> str:
    if credentials_header is None or not credentials_header.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz veya süresi dolmuş token",
        )

    try:
        decoded = auth.verify_id_token(credentials_header.credentials)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz veya süresi dolmuş token",
        ) from None

    uid = decoded.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz veya süresi dolmuş token",
        )
    return uid
