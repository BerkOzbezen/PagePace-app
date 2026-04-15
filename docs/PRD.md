[PRD.md](https://github.com/user-attachments/files/26762493/PRD.md)
# 📚 PagePace — Product Requirements Document (PRD)

---

## 1. Ürün Özeti

### 1.1 Vizyon

> *"Her okuyucunun kişisel okuma koçu — kaç sayfada bitireceğini, ne kadar ilerlediğini ve okuma alışkanlıklarını gerçek verilerle göster."*

PagePace, kitap okuyan bireylerin okuma hızlarını ölçen, kişisel istatistiklerini takip eden ve arkadaşlarıyla okuma deneyimini paylaşmalarına olukan tanıyan bir mobil uygulamadır.

### 1.2 Problem Tanımı

Goodreads'in 150 milyonun üzerinde kullanıcısı kitap listesi tutuyor; ancak mevcut hiçbir popüler uygulama şu soruları yanıtlayamıyor:

- *"Bu kitabı kaç saatte bitiririm?"*
- *"Geçen aya göre okuma hızım arttı mı?"*
- *"En verimli hangi saatte okuyorum?"*
- *"Arkadaşımla aramızda kim daha düzenli okuyor?"*

Bu bilgi boşluğu, özellikle yıllık okuma hedefi koyan 52+ milyon okuyucu için somut bir acı noktasıdır.

### 1.3 Çözüm

Kullanıcı her okuma oturumunda zamanlayıcıyı başlatır, bitince bulunduğu sayfayı girer. Uygulama bu verileri biriktirir; okuma hızını hesaplar, kalan sayfaya göre bitiş tarihi tahmin eder, haftalık/aylık istatistikler sunar ve arkadaşlarıyla karşılaştırmalı görünüm sağlar.

---

## 2. Hedef Kitle

### 2.1 Birincil Kullanıcı Segmenti

| Segment | Tanım | Büyüklük |
|---|---|---|
| Hedef okuyucular | Yılda 5+ kitap okuyan, okuma hedefi koyan bireyler | ~52M (r/52book topluluğu ve benzerleri) |
| Öğrenciler | Zorunlu okuma listesiyle takip eden üniversite öğrencileri | ~200M global |
| Profesyonel okuyucular | İş/kişisel gelişim kitaplarını takip eden çalışanlar | ~80M global |

### 2.2 Kullanıcı Personası

**Persona 1 — "Hedefli Ayşe"**  
- 26 yaşında, yazılım geliştirici  
- Yılda 24 kitap okuma hedefi var  
- Goodreads kullanıyor ama "ne zaman bitireceğimi bilmiyorum" diye şikayet ediyor  
- Spotify istatistiklerini seviyor, okuma için de benzerini istiyor  

**Persona 2 — "Rekabetçi Mert"**  
- 23 yaşında, üniversite öğrencisi  
- Arkadaş grubuyla okuma yarışması yapıyor  
- Excel ile takip etmeye çalıştı, sürdüremedi  
- Anlık karşılaştırma ve bildirim istiyor  

---

## 3. MVP Kapsamı

### 3.1 Kapsam İçindeki Özellikler (v1.0)

#### Modül 1 — Kimlik Doğrulama
- [ ] Google ile giriş (Firebase Auth)
- [ ] Apple ile giriş (Firebase Auth)
- [ ] E-posta / şifre ile kayıt ve giriş
- [ ] Şifre sıfırlama
- [ ] Oturum yönetimi (otomatik giriş)

#### Modül 2 — Kitap Yönetimi
- [ ] Kitap ekleme (başlık + toplam sayfa sayısı + kapak fotoğrafı)
- [ ] Open Library API ile ISBN tarama → otomatik bilgi doldurma
- [ ] Kitap düzenleme ve silme
- [ ] Kitap durumu: Okuyorum / Tamamlandı / Okumak İstiyorum
- [ ] Aktif kitap listesi ve tamamlanan kitaplar rafı

#### Modül 3 — Okuma Oturumu
- [ ] Oturum başlatma (zamanlayıcı — başlat / duraklat / bitir)
- [ ] Oturum sonu sayfa girişi ("Şu an kaçıncı sayfadasın?")
- [ ] Oturum geçmişi (tarih + süre + sayfa ilerleme)
- [ ] Arka planda zamanlayıcı desteği (uygulama minimize edilince devam eder)
- [ ] Manuel oturum ekleme (zamanlayıcı kullanmadan geçmiş giriş)

#### Modül 4 — Hız & Tahmin Motoru
- [ ] Kişisel okuma hızı hesaplama (son 5 oturumun ağırlıklı ortalaması — sayfa/saat)
- [ ] Kalan sayfa × okuma hızı → "Bu kitabı ~X saatte bitirirsin" tahmini
- [ ] Hedef bitiş tarihi girişi → "Günde kaç sayfa okumalısın?" hesabı
- [ ] Yetersiz veri durumu için graceful fallback (minimum 2 oturum şartı)
- [ ] Hız trend grafiği (son 4 hafta, kitap bazlı)

#### Modül 5 — İstatistik & Grafikler
- [ ] Haftalık okuma süresi bar grafiği
- [ ] Aylık okuma süresi bar grafiği
- [ ] En verimli okuma saati analizi (heatmap — sabah / öğlen / akşam / gece)
- [ ] Okuma streak takvimi (GitHub contributions görselleştirmesi)
- [ ] Yıllık özet: toplam kitap sayısı, toplam sayfa, toplam saat
- [ ] Kitap başına istatistik sayfası (oturum sayısı, ortalama süre, hız değişimi)

#### Modül 6 — Bildirimler
- [ ] Günlük okuma hatırlatıcısı (kullanıcı tanımlı saat)
- [ ] Streak kırılma uyarısı ("Bugün henüz okumadın!")
- [ ] Hedef tarihi yaklaşma bildirimi ("Hedefe 3 gün kaldı, 20 sayfa geride")
- [ ] Kitap tamamlama kutlaması (uygulama içi + bildirim)

#### Modül 7 — Sosyal Özellikler
- [ ] Kullanıcı profili (kullanıcı adı + avatar + biyografi)
- [ ] Arkadaşlık isteği sistemi (kullanıcı adıyla ara → istek gönder → karşı taraf onaylar)
- [ ] Davet linki ile arkadaş ekleme (tek kullanımlık deep link)
- [ ] Arkadaş listesi yönetimi (kabul et / reddet / kaldır)
- [ ] Arkadaş okuma istatistikleri görüntüleme (yalnızca karşılıklı arkadaş olanlar)
- [ ] Karşılaştırma ekranı (sen vs. arkadaş — haftalık okuma süresi grafik)
- [ ] Paylaşılabilir istatistik kartı üretimi (Spotify Wrapped tarzı görsel — screenshot_widget)
- [ ] **Profili Gizle** ayarı: aktif edildiğinde kullanıcı arkadaş listesinde görünmez, istatistikleri hiç kimseye gösterilmez; mevcut arkadaşlıklar korunur ancak o kullanıcının verisi gizlenir

### 3.2 Kapsam Dışındaki Özellikler (v1.0 sonrası)

| Özellik | Planlanan Versiyon |
|---|---|
| Goodreads CSV import | v1.1 |
| Okuma notları ve alıntı kaydetme | v1.1 |
| Kilit ekranı widget (ilerleme barı) | v1.1 |
| Barkod ile kitap ekleme | v1.1 |
| Grup okuma modu (kitap kulübü) | v1.2 |
| Sesli kitap desteği | v1.2 |
| E-kitap entegrasyonu (Kindle) | v2.0 |

---

## 4. Kullanıcı Hikayeleri (User Stories)

### Kimlik Doğrulama
- **US-01:** Kullanıcı olarak Google hesabımla hızlıca kayıt olmak istiyorum, böylece form doldurmadan uygulamaya başlayabilirim.
- **US-02:** Kullanıcı olarak uygulamayı her açtığımda tekrar giriş yapmak istemiyorum, oturumum açık kalsın.

### Kitap Yönetimi
- **US-03:** Kullanıcı olarak yeni bir kitap eklemek istiyorum; başlığını, toplam sayfa sayısını ve kapağını girebilmeliyim.
- **US-04:** Kullanıcı olarak ISBN numarasını tarayarak kitap bilgilerinin otomatik dolmasını istiyorum, manuel girişten kaçınmak için.
- **US-05:** Kullanıcı olarak tamamladığım kitapları ayrı bir rafta görmek istiyorum.

### Okuma Oturumu
- **US-06:** Kullanıcı olarak okumaya başlarken zamanlayıcıyı tek dokunuşla başlatmak istiyorum.
- **US-07:** Kullanıcı olarak okumayı bırakırken "kaçıncı sayfadasın?" sorusunu yanıtlayarak oturumu kaydetmek istiyorum.
- **US-08:** Kullanıcı olarak telefona gelen bir arama veya bildirim nedeniyle uygulamayı kapatsam bile zamanlayıcının durmadan devam etmesini istiyorum.

### Hız & Tahmin
- **US-09:** Kullanıcı olarak "bu kitabı kaç saate bitiririm?" sorusunun yanıtını görmek istiyorum; bu tahmin geçmiş okuma hızıma dayansın.
- **US-10:** Kullanıcı olarak hedef bitiş tarihini girerek "günde kaç sayfa okumam gerekiyor?" bilgisini görmek istiyorum.

### İstatistikler
- **US-11:** Kullanıcı olarak haftalık ve aylık okuma süre grafiklerimi görmek istiyorum.
- **US-12:** Kullanıcı olarak en verimli hangi saatte okuduğumu öğrenmek istiyorum.
- **US-13:** Kullanıcı olarak okuma serimimin (streak) devam ettiğini takip etmek ve kaybetmemek istiyorum.

### Sosyal
- **US-14:** Kullanıcı olarak arkadaşımı kullanıcı adıyla bulup takip listeme eklemek istiyorum.
- **US-15:** Kullanıcı olarak arkadaşımın bu hafta kaç sayfa okuduğunu görmek istiyorum.
- **US-16:** Kullanıcı olarak yıllık okuma istatistiklerimi görsel bir kartla Instagram'da paylaşmak istiyorum.
- **US-17:** Kullanıcı olarak istatistiklerimin kimler tarafından görüleceğini kontrol etmek istiyorum.

---

## 5. Teknik Gereksinimler

### 5.1 Platform & Teknoloji Stack

| Katman | Teknoloji | Gerekçe |
|---|---|---|
| Framework | Flutter 3.x | iOS + Android tek kod tabanı |
| Dil desteği | i18n (flutter_localizations) | Türkçe + İngilizce (v1.0); ilerleyen versiyonlarda genişletilebilir |
| Dil | Dart | Flutter native |
| Kimlik doğrulama | Firebase Auth | Google + Apple + e-posta, hazır SDK |
| Bulut veritabanı | Firebase Firestore | Sosyal özellikler için gerçek zamanlı sync |
| Yerel depolama | Hive | Offline-first, hızlı okuma/yazma |
| Grafikler | fl_chart | Flutter native, özelleştirilebilir |
| Bildirimler | flutter_local_notifications | iOS + Android yerel bildirim |
| Ödeme | RevenueCat | iOS + Android tek entegrasyon |
| Paylaşım kartı | screenshot_widget | Widget → PNG dönüşümü |
| API | Open Library API | Ücretsiz, ISBN + kapak desteği |
| Crash takibi | Sentry | Gerçek zamanlı hata izleme |
| Analitik | Mixpanel | Kullanıcı davranışı funnel analizi |

### 5.2 Veri Modeli (Firestore)

```
users/
  {userId}/
    displayName: string
    email: string
    avatarUrl: string
    bio: string
    privacySettings: { stats: "public" | "friends" | "private" }
    createdAt: timestamp

    books/
      {bookId}/
        title: string
        totalPages: number
        coverUrl: string
        isbn: string
        status: "reading" | "completed" | "wishlist"
        currentPage: number
        targetDate: timestamp | null
        addedAt: timestamp
        completedAt: timestamp | null

        sessions/
          {sessionId}/
            startPage: number
            endPage: number
            durationSeconds: number
            startedAt: timestamp
            endedAt: timestamp

    stats/
      {userId}/
        totalPagesAllTime: number
        totalBooksCompleted: number
        totalReadingSeconds: number
        currentStreak: number
        longestStreak: number
        lastReadDate: string (YYYY-MM-DD)

friends/
  {userId}/
    friendIds: array<string>
    pendingRequests: array<string>
```

### 5.3 Performans Gereksinimleri

| Metrik | Hedef |
|---|---|
| Uygulama açılış süresi (cold start) | < 2 saniye |
| Zamanlayıcı başlatma gecikmesi | < 100ms |
| Grafik render süresi | < 500ms |
| Offline çalışma | Tüm çekirdek özellikler internet gerektirmez |
| Firestore sync (sosyal) | < 3 saniye |

### 5.4 Güvenlik Gereksinimleri

- Firestore Security Rules: Kullanıcı yalnızca kendi verisini okur/yazar
- Arkadaş istatistikleri: Yalnızca **karşılıklı onaylı arkadaşlık** ilişkisi olan kullanıcılar birbirinin verisini okuyabilir (Firestore Rules ile zorunlu)
- "Profili Gizle" aktifse: o kullanıcının tüm istatistik dökümanları Rules katmanında herkese kapalı hale gelir
- Arkadaşlık isteği akışı: istek → beklemede → onay/red; onaylanmadan veri erişimi yok
- Firebase Auth token yenileme: Otomatik
- Hassas veri: Şifre Firebase'de saklanmaz (OAuth / Firebase managed)

---

## 6. UX & Tasarım Prensipleri

### 6.1 Tasarım Değerleri
- **Sadelik önce:** Her ekranda tek bir ana eylem
- **Veri odaklı:** Sayılar ve grafikler ön planda
- **Kutlama kültürü:** Kitap bitince konfeti, streak milestonelarda animasyon
- **Dark mode:** Gece okuma seanslarına uygun, varsayılan sistem teması

### 6.2 Navigasyon Yapısı

```
Bottom Navigation Bar:
├── Ana Sayfa        → Aktif kitap + bugünün hedefi + mini streak
├── Kitaplık         → Tüm kitaplar (okuyorum / tamamlandı / liste)
├── İstatistikler    → Grafikler + streak + yıllık özet
└── Sosyal           → Arkadaşlar + karşılaştırma + paylaşım kartı

Profil (sağ üst köşe):
└── Hesap ayarları + gizlilik + premium + çıkış
```

### 6.3 Kritik Kullanıcı Akışı — Okuma Oturumu

```
Ana Sayfa
  → [Okumaya Başla] butonu
    → Zamanlayıcı aktif (büyük dijital saat + kitap adı)
      → [Duraklat] veya [Bitir]
        → "Kaçıncı sayfadasın?" modalı
          → Kaydet
            → Oturum özeti (süre + sayfa + kazanılan XP benzeri motivasyon mesajı)
              → Ana Sayfa (güncellenmiş ilerleme)
```

---

## 7. Gelir Modeli

### 7.1 Freemium Yapısı

| Özellik | Ücretsiz | Premium ($2.99/ay veya $19.99/yıl) |
|---|---|---|
| Aktif kitap sayısı | 3 | Sınırsız |
| Oturum geçmişi | Son 30 gün | Tüm zamanlar |
| Grafikler | Haftalık | Haftalık + Aylık + Yıllık |
| Okuma hızı tahmini | ✓ | ✓ |
| Günlük bildirim | ✓ | ✓ |
| Arkadaş ekleme | 3 arkadaş | Sınırsız |
| Paylaşım kartı | Watermarklı | Watermarksız + özel temalar |
| Veri export (CSV) | ✗ | ✓ |
| Kilit ekranı widget | ✗ | ✓ (v1.1) |

### 7.2 Gelir Hedefi (12. ay)

| Metrik | Hedef |
|---|---|
| Toplam indirme | 50.000 |
| Aktif kullanıcı (MAU) | 15.000 |
| Premium dönüşüm oranı | %5 |
| Aylık premium kullanıcı | 750 |
| Aylık gelir | ~$2.250 |

---

## 8. Başarı Metrikleri (KPI)

### 8.1 Ürün Metrikleri

| Metrik | Hedef (3. ay) | Hedef (6. ay) |
|---|---|---|
| Günlük aktif kullanıcı (DAU) | 1.000 | 5.000 |
| Ortalama oturum sayısı / kullanıcı / hafta | 4 | 5 |
| D7 retention | %35 | %40 |
| D30 retention | %20 | %28 |
| Ortalama oturum süresi | 8 dk | 10 dk |
| Paylaşım kartı oluşturma oranı | %15 | %25 |

### 8.2 İş Metrikleri

| Metrik | Hedef (6. ay) |
|---|---|
| App Store ortalama puanı | 4.5+ |
| Premium dönüşüm | %5 |
| Churn rate (aylık) | < %8 |
| Organik indirme oranı | > %60 |

---

## 9. 8 Haftalık Geliştirme Takvimi

| Hafta | Odak | Teslim |
|---|---|---|
| 1 | Altyapı: Flutter setup, Firebase Auth, Hive, kitap CRUD | Çalışan auth + kitap ekleme |
| 2 | Okuma oturumu: zamanlayıcı, sayfa girişi, oturum kaydı | Tam oturum akışı |
| 3 | Hız motoru: okuma hızı hesaplama, tahmin algoritması | Hız + tahmini gösteren ekran |
| 4 | İstatistikler: fl_chart grafikleri, streak, heatmap | İstatistik ekranı |
| 5 | Sosyal: Firestore sync, arkadaş ekleme, karşılaştırma | Sosyal modül |
| 6 | Bildirimler, paylaşım kartı, UI polish, dark mode | Eksiksiz UI |
| 7 | Premium (RevenueCat), beta test (TestFlight + Play), bug fix | Beta yayını |
| 8 | Store listeleme, ASO, Product Hunt + Reddit lansmanı | Canlı yayın |

---

## 10. Riskler & Azaltma Stratejileri

| Risk | Olasılık | Etki | Azaltma |
|---|---|---|---|
| Hafta 5 sosyal modülü scope'u şişirir | Orta | Yüksek | Sosyal minimum: sadece haftalık sayfa karşılaştırması; gerisi v1.1'e |
| Yeterli kullanıcı olmadan sosyal boş hissettiriyor | Yüksek | Orta | Sosyal özelliği arkadaşsız da anlamlı tut (kişisel istatistik vurgusu) |
| Open Library API'de kitap bulunamıyor | Düşük | Düşük | Manuel giriş her zaman fallback olarak mevcut |
| App Store review gecikmesi | Orta | Orta | Hafta 7'de TestFlight ile paralel review süreci başlat |
| RevenueCat entegrasyon karmaşıklığı | Düşük | Orta | Hafta 6'ya bütün bir gün ayır; dokümantasyon iyi |

---

## 11. Açık Sorular

- [x] ~~Uygulama adı~~ → **PagePace** olarak karar verildi
- [x] ~~Sosyal gizlilik~~ → Arkadaşlık isteği sistemi + "Profili Gizle" ayarı olarak karar verildi
- [x] ~~Uygulama dili~~ → v1.0: Türkçe + İngilizce; sonraki versiyonlarda ek dil desteği
- [ ] Yıllık okuma raporu (Spotify Wrapped) sadece yıl sonunda mı, yoksa isteğe bağlı her an mı üretilebilir olacak?
- [ ] Arkadaşlık isteği bildirim kanalı: sadece push mu, uygulama içi bildirim de olacak mı?

---

## 12. Ekler

### 12.1 Rekabet Analizi

#### Ana Rakipler

**Goodreads** (Amazon · 150M+ kullanıcı)

Sektörün tartışmasız lideri. Devasa kitap veritabanı, sosyal özellikler ve Amazon/Kindle entegrasyonu ile rakipsiz bir kitaplık ve keşif platformu. Ancak Amazon'un 2013'te satın almasının ardından gelişimi durma noktasına geldi — arayüz hâlâ 2011 hissettiriyor, dark mode Mart 2026'da eklendi, "Did Not Finish" rafı yerel özellik olarak yeni geldi. Zamanlayıcı, kişisel hız hesaplama ve bitiş tahmini hiç yok. Öneri motoru okuyucu zevkinden çok Amazon satış önceliklerine göre çalışıyor.

**StoryGraph** (Bağımsız · 5M+ kullanıcı · 2025 Apple App Store Ödülü)

Goodreads'in en güçlü rakibi. Ruh hali takibi, tür analizi, çeyrek yıldız derecelendirme ve yıl sonu raporu ile istatistik odaklı okuyucuların tercihi. Zamanlayıcı yok, sosyal özellikler kasıtlı olarak minimal tutulmuş — yorum yapma Şubat 2026'ya kadar mevcut değildi. Hız tahmini kısmen var ama zamanlayıcı verisine dayanmıyor.

**Bookly** (Cross-platform · 1M+ kullanıcı)

En yakın teknik rakip. Zamanlayıcı, streak, günlük hedef ve görsel istatistikler içeriyor. Motivasyon odaklı tasarımı güçlü. Kritik eksikler: sosyal özellik hiç yok, free versiyonu 10 kitapla sınırlı, bitiş tarihi tahmini yok.

**Bookmory** (Cross-platform · Büyüyen)

Minimalist ve sade deneyim. Sayfa + süre takibi, alıntı kaydetme, journal hissi. Sosyal özellik yok, hız hesaplama yok, hedef odaklı kitleye hitap etmiyor.

**Readng / Leio ve benzerleri** (Küçük ölçekli)

Zamanlayıcı + basit grafik sunan birkaç uygulama var, ancak ya terk edilmiş (son güncelleme 2021) ya çok temel ya da yalnızca iOS. Bu segment fiilen rakipsiz.

---

#### Özellik Karşılaştırma Matrisi

| Özellik | PagePace | Goodreads | StoryGraph | Bookly | Bookmory |
|---|:---:|:---:|:---:|:---:|:---:|
| Okuma zamanlayıcısı | ✅ | ❌ | ❌ | ✅ | Kısmi |
| Kişisel hız hesaplama | ✅ | ❌ | ❌ | Kısmi | ❌ |
| Bitiş tarihi tahmini | ✅ | ❌ | ❌ | ❌ | ❌ |
| Streak sistemi | ✅ | ❌ | ❌ | ✅ | ❌ |
| Arkadaş karşılaştırma | ✅ | Sadece liste | Minimal | ❌ | ❌ |
| Arkadaşlık isteği sistemi | ✅ | ✅ | Kısmi | ❌ | ❌ |
| Haftalık istatistik grafikleri | ✅ | ❌ | ✅ | ✅ | Kısmi |
| Paylaşılabilir istatistik kartı | ✅ | ❌ | ✅ | ❌ | ❌ |
| Profil gizleme | ✅ | Kısmi | Kısmi | ❌ | ❌ |
| Türkçe dil desteği | ✅ | ❌ | ❌ | ❌ | ❌ |

---

#### PagePace'i Rakiplerden Ayıran 5 Temel Fark

**1. Zamanlayıcı + Tahmin Motoru birlikte**
Bookly zamanlayıcı yapıyor ama bitiş tahmini yok. StoryGraph istatistik yapıyor ama zamanlayıcı yok. PagePace, gerçek okuma verisine dayanan bitiş tahmini sunan tek uygulama.

**2. Zamanlayıcılı uygulama + Sosyal karşılaştırma birlikte**
Bookly'nin sosyal özelliği hiç yok. Goodreads'in zamanlayıcısı yok. "Arkadaşım bu hafta kaç saat okudu, ben kaç saat?" sorusu mevcut uygulamaların hiçbirinde cevaplanamıyor.

**3. Türkçe dil desteği**
Sektördeki hiçbir rakip Türkçe sunmuyor. Türkiye okuma uygulaması pazarında yerel seçenek boşluğu var — bu TR App Store'da neredeyca rakipsiz başlangıç anlamına geliyor.

**4. Gizlilik odaklı sosyal deneyim**
Karşılıklı arkadaşlık isteği onayı + Profil Gizle ayarı ile kullanıcı verisinin kimin göreceğini tam kontrol altında tutuyor. Goodreads'in açık ve zayıf modere edilen sosyal yapısına karşı net bir farklılaşma.

**5. Net segment odağı**
Goodreads herkese hitap ediyor. PagePace'in hedefi kristal net: yılda X kitap hedefi koyan, ilerlemeyi ölçmek isteyen, arkadaşlarıyla rekabet etmekten keyif alan okuyucu. Net segment = net mesaj = daha yüksek dönüşüm oranı.

---

#### Pazar Konumlandırma Özeti

Sektör şu an iki kutba ayrılmış: bir tarafta zamanlayıcı + streak odaklı uygulamalar (Bookly), diğer tarafta istatistik + sosyal uygulamalar (Goodreads, StoryGraph). Bu iki kutbu birleştiren, üstelik Türkçe dil desteği ve gizlilik odaklı sosyal mekanikle gelen bir uygulama henüz yok. PagePace bu boşluğa giriyor.

### 12.2 Sözlük

| Terim | Tanım |
|---|---|
| Okuma hızı | Sayfa/saat cinsinden, son 5 oturumun ağırlıklı ortalaması |
| Oturum | Zamanlayıcı başlatıldığından bitirildiğine kadar geçen tek okuma birimi |
| Streak | Üst üste okuma yapılan gün sayısı |
| Tahmin motoru | Kalan sayfa ÷ kişisel okuma hızı formülüyle bitiş süresi hesaplayan servis |
| MAU | Monthly Active Users — aylık aktif kullanıcı |

---

*Bu PRD, PagePace uygulaması için Future Talent Program kapsamında hazırlanmıştır. Versiyon güncellemeleri için GitHub repo geçmişine bakınız.*
