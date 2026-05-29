# Tech Stack

## Frontend
- Flutter (Dart) — cross-platform mobil uygulama
- Provider — state management (ThemeProvider)
- Go Router — navigasyon
- Dio — HTTP istekleri
- Firebase Auth — kimlik doğrulama
- SharedPreferences — kalıcı ayarlar

## Backend
- Python FastAPI — REST API
- Firebase Admin SDK — Firestore veritabanı
- OpenRouter API — AI kitap önerileri (meta-llama/llama modeli)
- httpx — async HTTP istekleri
- Uvicorn — ASGI sunucu

## Servis Seçim Gerekçeleri
- Flutter: tek kod tabanıyla iOS ve Android desteği
- FastAPI: hızlı geliştirme, otomatik API dokümantasyonu
- Firestore: gerçek zamanlı sync, offline destek, ücretsiz plan
- OpenRouter: Gemini rate limit sorunu nedeniyle tercih edildi, ücretsiz modeller mevcut

## AI Kullanımı
- Cursor IDE ile kod geliştirme (agent modu)
- OpenRouter API ile kitap önerisi özelliği
- Gemini API (geliştirme sürecinde test edildi)
