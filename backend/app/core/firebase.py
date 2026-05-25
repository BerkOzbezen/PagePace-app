import json
import os
import firebase_admin
from firebase_admin import credentials, firestore, auth
from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from dotenv import load_dotenv

load_dotenv()

_db = None


def _build_cred():
    cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
    if cred_json:
        cred_dict = json.loads(cred_json)
        return credentials.Certificate(cred_dict)
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
    return credentials.Certificate(cred_path)


def init_firebase():
    global _db
    for app in list(firebase_admin._apps.values()):
        firebase_admin.delete_app(app)
    firebase_admin.initialize_app(_build_cred())
    _db = firestore.client()
    return _db


def get_db():
    global _db
    if _db is None:
        init_firebase()
    return _db


db = init_firebase()
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> dict:
    token = credentials.credentials
    try:
        decoded = auth.verify_id_token(token, clock_skew_seconds=60)
        return decoded
    except Exception as e:
        print(f"Token verification failed: {type(e).__name__}: {e}")
        if "invalid_grant" in str(e) or "JWT" in str(e):
            print("Reinitializing Firebase...")
            init_firebase()
        raise HTTPException(status_code=401, detail=f"Token hatası: {str(e)}")
