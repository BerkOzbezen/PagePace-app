import json
import os
import re
from typing import Annotated, Any

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from google.cloud import firestore

from app.core.deps import get_uid
from app.core.firebase import db
from app.core.utils import doc_to_dict

router = APIRouter(prefix="/ai", tags=["ai"])


def _books_ref(db: firestore.Client, uid: str):
    return db.collection("users").document(uid).collection("books")


@router.get("/recommend")
async def recommend_books(uid: Annotated[str, Depends(get_uid)]):
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="OPENROUTER_API_KEY tanımlı değil",
        )

    books = [doc_to_dict(doc) for doc in _books_ref(db, uid).stream()]
    titles = [str(b.get("title", "")).strip() for b in books if b.get("title")]
    book_list = ", ".join(titles) if titles else "henüz kitap yok"

    prompt = f"""Kullanıcı şu kitapları okudu: {book_list}
Bu kitaplara göre 3 kitap öner. Her seferinde farklı kitaplar öner, aynı kitapları tekrarlama.
JSON formatında döndür:
{{"recommendations": [{{"title": "...", "author": "...", "reason": "..."}}]}}
Sadece JSON döndür, başka hiçbir şey yazma. Türkçe yanıt ver."""

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://pagepace.app",
        "X-Title": "PagePace",
    }

    payload = {
        "model": "nvidia/nemotron-3-super-120b-a12b:free",
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.8,
    }

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            data = response.json()
            text = data["choices"][0]["message"]["content"]
            cleaned = text.strip()
            if cleaned.startswith("```"):
                cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
                cleaned = re.sub(r"\s*```$", "", cleaned)
            parsed = json.loads(cleaned)
            recommendations = parsed.get("recommendations", [])
            normalized = [
                {
                    "title": str(item.get("title", "")),
                    "author": str(item.get("author", "")),
                    "reason": str(item.get("reason", "")),
                }
                for item in recommendations[:3]
                if isinstance(item, dict)
            ]
            return {"recommendations": normalized}
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="AI yanıtı işlenemedi",
        ) from None
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"AI önerisi alınamadı: {exc}",
        ) from exc