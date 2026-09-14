# Sıfır Atık

Sıfır Atık, kullanılabilir durumdaki atıkların ilan olarak paylaşılabildiği bir
Flutter mobil uygulamasıdır. Uygulamadaki temel amaç; karton, cam, plastik veya
elektronik gibi değerlendirilebilir atıkları ihtiyaç duyan kişilerle daha kolay
buluşturmaktır.

Projeyi şu anda Android odaklı olarak geliştirdim ve denemelerimi Android
emülatör üzerinde yaptım. Flutter altyapısı sayesinde proje iOS klasörünü de
içeriyor; ancak iOS tarafını ayrıca test etmedim.

## Projede Neler Var?

### Kullanıcı işlemleri

- E-posta ve şifre ile kayıt olma / giriş yapma
- Google ile giriş desteği
- Şifre sıfırlama akışı
- Uygulama açıldığında mevcut oturumu kontrol etme
- Çıkış yapma

### İlan işlemleri

- Atık ilanı oluşturma
- İlanlara fotoğraf ekleme
- İlan fotoğrafını güncelleme veya kaldırma
- Kendi ilanlarını görme, düzenleme ve silme
- İlanları kategoriye göre filtreleme
- İlanlarda başlık, kategori ve konuma göre arama yapma
- İlan oluştururken şehir ve ilçeyi arayarak seçme
- İlan kartlarında `Miktar • Konum` bilgisini standart şekilde gösterme

### Talep işlemleri

- Başka kullanıcıların ilanlarına talep gönderme
- Kullanıcının kendi ilanına talep göndermesini engelleme
- Gönderilen talepleri `Taleplerim` ekranında takip etme
- İlan sahibinin gelen talepleri kabul veya reddetmesi
- Talep durumunu `Beklemede`, `Kabul edildi` veya `Reddedildi` olarak gösterme
- Talep kabul edilince iletişim bilgisini açma
- Kabul edilen taleplerde arama veya WhatsApp üzerinden mesaj gönderme

### Firebase kullanımı

- Firebase Authentication ile kullanıcı girişi
- Firestore ile ilan ve talep verilerini kaydetme
- Firebase Storage ile ilan fotoğraflarını saklama
- Firestore güvenlik kurallarıyla ilan sahibi ve talep sahibi kontrolleri
- Storage kurallarıyla fotoğraf yükleme ve silme izinleri

## Ekran Görüntüleri

Uygulamanın temel akışını gösteren bazı ekranlar:

| Giriş | Ana ekran |
| --- | --- |
| <img src="screenshots/01-login.png" width="230" alt="Giriş ekranı"> | <img src="screenshots/02-home.png" width="230" alt="Ana ekran"> |

| İlanlar | İlan detayı |
| --- | --- |
| <img src="screenshots/03-listings.png" width="230" alt="İlan listesi"> | <img src="screenshots/05-listing-detail.png" width="230" alt="İlan detayı"> |

| İlan oluşturma | Taleplerim ve iletişim |
| --- | --- |
| <img src="screenshots/07-create-listing.png" width="230" alt="İlan oluşturma ekranı"> | <img src="screenshots/09-my-requests.png" width="230" alt="Taleplerim ve iletişim ekranı"> |

## Kullandığım Teknolojiler

- Flutter
- Dart
- Material 3
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Google Sign-In
- Image Picker
- URL Launcher
- Shared Preferences

## Kurulum

Projeyi çalıştırmadan önce Flutter SDK ve Android geliştirme ortamının hazır
olması gerekiyor.

```bash
flutter pub get
flutter run
```

Kod analizi ve testler için:

```bash
flutter analyze
flutter test
```

## Test Durumu

Projede widget testleri, repository testleri ve Firestore güvenlik kuralı
testleri bulunuyor. Şu anda testlerde özellikle şu akışları kontrol ediyorum:

- Giriş ekranındaki temel alanların görünmesi
- Şifre gücü ve kayıt formu davranışları
- Ana ekrandaki yönlendirmeler
- İlan oluşturma formu
- Fotoğraf kaldırma davranışı
- Arama ve kategori filtreleri
- Kullanıcının kendi ilanına talep gönderememesi
- Talep başarısız olduğunda yanlış başarı mesajı gösterilmemesi
- Talep durumlarının ekranda doğru görünmesi
- İlan düzenleme ve silme işlemlerinin talep verileriyle birlikte güncellenmesi
- Firestore kurallarında ilan sahibinin doğrulanması

Son kontrolde `flutter analyze` hatasız çalıştı ve `flutter test` ile 28 testin
tamamı geçti.

## Manuel Olarak Denediğim Akış

Android emülatörde iki farklı kullanıcıyla şu akışı manuel olarak kontrol ettim:

1. İlk kullanıcıyla giriş yaptım ve telefon numarasını SMS koduyla doğruladım.
2. Fotoğraflı bir atık ilanı oluşturdum.
3. İkinci kullanıcıyla giriş yapıp bu ilana talep gönderdim.
4. İlk kullanıcıyla gelen talebi gördüm ve talebi kabul ettim.
5. İkinci kullanıcıda talep durumunun güncellendiğini kontrol ettim.
6. Talep kabul edilince telefon bilgisinin açıldığını, arama ve WhatsApp
   seçeneklerinin göründüğünü denedim.

## Projenin Şu Anki Durumu

Proje şu anda Android emülatörde demo yapılabilecek seviyede. Kullanıcı giriş
yapabiliyor, ilan oluşturabiliyor, fotoğraf ekleyebiliyor, kendi ilanlarını
yönetebiliyor ve başka ilanlara talep gönderebiliyor.

iOS klasörü Flutter projesinin platform altyapısı olarak duruyor. iOS tarafında
kamera, galeri ve platform ayarları ayrıca test edilmediği için projeyi şu an
Android odaklı olarak değerlendiriyorum.

Play Store'a çıkarılacak bir sürüm için Android release imzasının ayrıca
hazırlanması gerekir.
