# PagePace
> Your reading, your pace.

Okuma hızını ölç, bitiş tarihini tahmin et, AI destekli kitap önerileri al.

Flutter + FastAPI ile geliştirilen cross-platform okuma takip uygulaması.

## 🚀 Canlı Demo
- **Web App:** https://pagepace-rosy.vercel.app
- **Backend API:** https://pagepace-app-production.up.railway.app

## ✨ Özellikler
- 📚 Kitap ekleme ve okuma takibi
- ⏱️ Zamanlayıcı ile okuma oturumu kaydetme
- 📊 Okuma istatistikleri (haftalık, yıllık, streak)
- 🤖 AI kitap önerisi (OpenRouter)
- 🌙 Dark mode
- 📖 Open Library entegrasyonu (kitap arama, kapak görseli)

## 🛠️ Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** FastAPI (Python)
- **Database:** Firebase Firestore
- **Auth:** Firebase Authentication
- **AI:** OpenRouter API
- **Deploy:** Vercel (frontend) + Railway (backend)

## 📁 Proje Yapısı
- `/frontend` — Flutter uygulaması
- `/backend` — FastAPI backend
- `/prodocs` — Geliştirme referans dokümanları
- `/docs` — PRD ve planlama

## 🔧 Kurulum
1. `backend/.env.example` dosyasını `.env` olarak kopyala
2. Firebase ve OpenRouter key'lerini ekle
3. Backend: `uvicorn main:app --reload`
4. Frontend: `flutter run`

📄 [PRD'yi görüntüle](docs/PRD.md)
