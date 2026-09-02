# Sıfır Atık

Sıfır Atık, kullanıcıların değerlendirilebilir atıklarını ilan olarak
paylaşabilmesini ve diğer ilanları keşfedebilmesini hedefleyen bir Flutter mobil
uygulamasıdır.

## Mevcut özellikler

- Material 3 uyumlu, responsive giriş ekranı
- E-posta ve şifre doğrulaması
- Şifre görünürlüğü ve şifre güç göstergesi
- Beni hatırla seçeneği
- Google ile giriş butonu
- Giriş sırasında loading durumu ve hata bildirimi
- Atık ilanı verme ve ilanları görme seçeneklerini sunan ana ekran taslağı
- Doğrulamalı atık ilanı oluşturma formu
- Arama ve kategori filtreleri içeren örnek ilan listesi

## Uygulamadan ekranlar

| Giriş | Ana ekran |
| --- | --- |
| <img src="screenshots/01-login.png" width="260" alt="Giriş ekranı"> | <img src="screenshots/02-home.png" width="260" alt="Ana ekran"> |

| İlanlar | Filtre sonucu |
| --- | --- |
| <img src="screenshots/03-listings.png" width="260" alt="İlan listesi"> | <img src="screenshots/04-empty-filter.png" width="260" alt="Filtre sonucu boş ekran"> |

| İlan detayı | Talep gönderildi |
| --- | --- |
| <img src="screenshots/05-listing-detail.png" width="260" alt="İlan detayı"> | <img src="screenshots/06-interest-sent.png" width="260" alt="Talep gönderildi ekranı"> |

| İlan oluşturma |
| --- |
| <img src="screenshots/07-create-listing.png" width="260" alt="İlan oluşturma ekranı"> |

## Projeyi çalıştırma

Flutter SDK'nın kurulu olduğundan emin olduktan sonra:

```bash
flutter pub get
flutter run
```

Kod kalitesi ve testleri kontrol etmek için:

```bash
flutter analyze
flutter test
```

## Proje durumu

Uygulama geliştirme aşamasındadır. İlan oluşturma ve listeleme arayüzleri örnek
verilerle hazırlanmıştır; henüz Firestore'a veri kaydetmez veya gerçek ilanları
çekmez. Google ile giriş arayüzü hazırdır; gerçek Firebase Authentication
bağlantısı sonraki aşamada tamamlanacaktır.
