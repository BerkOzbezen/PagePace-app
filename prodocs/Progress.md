# Progress Log

## Hafta 1-2: Proje Kurulumu
- Flutter projesi oluşturuldu
- FastAPI backend kuruldu
- Firebase Auth entegrasyonu tamamlandı
- Temel ekranlar (login, register, books) oluşturuldu

## Hafta 3-4: Core Özellikler
- Kitap ekleme/listeleme backend'e bağlandı
- Zamanlayıcı ekranı tamamlandı
- Oturum kaydetme özelliği eklendi
- Open Library API entegrasyonu (kitap arama, kapak görseli)

## Hafta 5-6: İstatistikler ve Profil
- İstatistik ekranı (weekly, yearly, streak, heatmap)
- Profil ekranı gerçek Firebase verisiyle güncellendi
- Dark mode + Settings ekranı eklendi
- Kitap kapakları Open Library'den çekiliyor

## Hafta 7-8: AI ve Polish
- OpenRouter API ile AI kitap önerisi özelliği eklendi
- Frontend polish (animasyonlar, boş durumlar, motivasyon kartları)
- Streak banner, gamification elementleri eklendi
- Kitap seçici zamanlayıcıda eklendi

## Alınan Kararlar
- Gemini API rate limit sorunu → OpenRouter'a geçildi
- ISBN arama kaldırıldı → sadece başlık araması
- showModalBottomSheet → Navigator.push (assertion hatası çözümü)

## Karşılaşılan Hatalar
- Firebase credentials expire sorunu: her oturumda yeni key gerekiyor
- Token verification clock_skew: clock_skew_seconds=60 ile çözüldü
- Flutter assertion _dependents.isEmpty: Navigator.push ile çözüldü
