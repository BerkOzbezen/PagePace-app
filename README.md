# PagePace
> Your reading, your pace.

Okuma hızını ölç, bitiş tarihini tahmin et, AI destekli kitap önerileri al.
Flutter + FastAPI ile geliştirilen cross-platform okuma takip uygulaması.

## 🚀 Canlı Demo
- **Web App:** https://pagepace-rosy.vercel.app
- **Backend API:** https://pagepace-app-production.up.railway.app

## ✨ Özellikler
- 📚 Kitap ekleme, okuma takibi ve ilerleme kaydı
- ⏱️ Zamanlayıcı ile okuma oturumu kaydetme
- 📊 Okuma istatistikleri (haftalık, yıllık, streak, heatmap)
- 🤖 AI kitap önerisi (OpenRouter — nvidia/nemotron modeli)
- 👥 Arkadaş sistemi ve karşılaştırma
- 🌙 Dark mode
- 📖 Open Library entegrasyonu (kitap arama + kapak görseli)

## 🛠️ Tech Stack
- **Frontend:** Flutter (Dart) — iOS, Android, Web
- **Backend:** FastAPI (Python)
- **Database:** Firebase Firestore
- **Auth:** Firebase Authentication
- **AI:** OpenRouter API (nvidia/nemotron-3-super-120b-a12b:free)
- **Deploy:** Vercel (frontend) + Railway (backend)

## 📁 Proje Yapısı
```
PagePace-app/
├── frontend/          # Flutter uygulaması
├── backend/           # FastAPI backend
├── prodocs/           # Geliştirme referans dokümanları
│   ├── tech-stack.md
│   ├── DesignSystem.md
│   └── Progress.md
├── docs/              # PRD ve planlama
│   ├── PRD.md
│   └── PLAN.md
├── .env.example       # Örnek environment variables
└── README.md
```

## 🔧 Kurulum

### Backend
```bash
cd backend
cp .env.example .env
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

## 🌍 Deploy

### Backend (Railway)
1. Railway'de yeni proje oluştur
2. GitHub repo'yu bağla, Root Directory: `backend`
3. Environment variables ekle (`FIREBASE_CREDENTIALS_JSON`, `OPENROUTER_API_KEY`)
4. Deploy et

### Frontend (Vercel)
```bash
cd frontend
flutter build web --release
vercel deploy build/web --prod
```

## 📄 Dokümanlar
- **PRD:** [docs/PRD.md](docs/PRD.md) — Problem, hedef kitle, özellikler
- **Tech Stack:** [prodocs/tech-stack.md](prodocs/tech-stack.md) — Teknoloji seçimleri
- **Design System:** [prodocs/DesignSystem.md](prodocs/DesignSystem.md) — UI kuralları
- **Progress:** [prodocs/Progress.md](prodocs/Progress.md) — Geliştirme günlüğü
