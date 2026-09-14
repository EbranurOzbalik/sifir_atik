# Sıfır Atık

Sıfır Atık, kullanılabilir durumdaki atıkların ilan olarak paylaşılabildiği bir
Flutter mobil uygulamasıdır. Projede temel amaç; karton, cam, plastik veya
elektronik gibi değerlendirilebilir atıkların ihtiyaç duyan kişiler tarafından
daha kolay bulunmasını sağlamaktır.

Bu projeyi Android odaklı geliştirdim ve denemelerimi Android emülatör üzerinde
yaptım. Flutter projesi olduğu için iOS klasörü de duruyor; fakat iOS tarafını
ayrıca test etmedim.

## Projenin Amacı

Uygulamada kullanıcılar ellerindeki atıkları ilan olarak paylaşabiliyor. Başka
bir kullanıcı ilana talep gönderebiliyor. İlan sahibi talebi kabul ederse iletişim
bilgisi açılıyor ve kullanıcılar arama ya da WhatsApp üzerinden iletişim
kurabiliyor.

Bu şekilde uygulama sadece ilanların listelendiği bir ekran olmaktan çıkıp, ilan
oluşturma ve talep takibi olan daha tamamlanmış bir akışa dönüşüyor.

## Uygulamada Neler Var?

### Giriş ve kullanıcı akışı

- E-posta ve şifre ile kayıt olma / giriş yapma
- Google ile giriş desteği
- Şifre sıfırlama ekranı
- Uygulama açıldığında oturum kontrolü
- Çıkış yapma

### İlan akışı

- Atık ilanı oluşturma
- İlanlara fotoğraf ekleme
- Fotoğrafı güncelleme veya kaldırma
- Şehir ve ilçeyi arayarak seçme
- İlanları listeleme ve detayını görme
- Kategoriye göre filtreleme
- Başlık, kategori ve konuma göre arama yapma
- Kullanıcının kendi ilanlarını düzenlemesi ve silmesi

### Talep akışı

- Başka kullanıcının ilanına talep gönderme
- Kullanıcının kendi ilanına talep göndermesini engelleme
- Gönderilen talepleri takip etme
- İlan sahibinin talebi kabul veya reddetmesi
- Talep durumunu beklemede, kabul edildi veya reddedildi olarak gösterme
- Kabul edilen talepte telefon bilgisini açma
- Arama ve WhatsApp üzerinden iletişim kurma

### Veritabanı ve dosya tarafı

- Firebase Authentication ile kullanıcı işlemleri
- Cloud Firestore ile ilan ve talep verilerini tutma
- Firebase Storage ile ilan fotoğraflarını saklama
- Firestore güvenlik kurallarıyla ilan ve talep sahipliğini kontrol etme
- Storage kurallarıyla fotoğraf yükleme ve silme izinlerini sınırlandırma

## Ekran Görüntüleri

### Giriş ve ana ekran

| Giriş | Ana ekran |
| --- | --- |
| <img src="screenshots/01-login.png" width="260" alt="Giriş ekranı"> | <img src="screenshots/02-home.png" width="260" alt="Ana ekran"> |

### İlan akışı

| İlanlar | İlan detayı |
| --- | --- |
| <img src="screenshots/03-listings.png" width="260" alt="İlan listesi"> | <img src="screenshots/05-listing-detail.png" width="260" alt="İlan detayı"> |

### İlan oluşturma ve talep takibi

| İlan oluşturma | Taleplerim ve iletişim |
| --- | --- |
| <img src="screenshots/07-create-listing.png" width="260" alt="İlan oluşturma ekranı"> | <img src="screenshots/09-my-requests.png" width="260" alt="Taleplerim ve iletişim ekranı"> |

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

## Projeyi Çalıştırma

Flutter SDK ve Android geliştirme ortamı hazır olduktan sonra proje şu komutlarla
çalıştırılabilir:

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
testleri bulunuyor. Testlerde özellikle şu kısımları kontrol ettim:

- Giriş ekranındaki temel alanlar
- Şifre gücü ve kayıt formu davranışı
- Ana ekrandaki yönlendirmeler
- İlan oluşturma formu
- Fotoğraf kaldırma işlemi
- Arama ve kategori filtreleri
- Kullanıcının kendi ilanına talep gönderememesi
- Talep başarısız olduğunda yanlış başarı mesajı gösterilmemesi
- Talep durumlarının ekranda doğru görünmesi
- İlan düzenleme ve silme işlemlerinin talep verileriyle birlikte güncellenmesi
- Firestore kurallarında ilan sahibi kontrolü

Son kontrolde `flutter analyze` hatasız çalıştı ve `flutter test` ile 28 testin
tamamı geçti.

## Manuel Denediğim Akış

Android emülatörde iki farklı kullanıcıyla şu akışı manuel olarak denedim:

1. İlk kullanıcıyla giriş yaptım.
2. İlan oluştururken telefon numarasını SMS koduyla doğruladım.
3. Fotoğraflı bir atık ilanı oluşturdum.
4. İkinci kullanıcıyla giriş yapıp bu ilana talep gönderdim.
5. İlk kullanıcıyla gelen talebi kabul ettim.
6. İkinci kullanıcıda talebin kabul edildiğini ve iletişim alanının açıldığını
   kontrol ettim.
7. Arama ve WhatsApp butonlarının göründüğünü denedim.

## Şu Anki Durum

Proje şu anda Android emülatörde demo yapılabilecek seviyede. Kullanıcı giriş
yapabiliyor, ilan oluşturabiliyor, fotoğraf ekleyebiliyor, şehir/ilçe seçebiliyor,
kendi ilanlarını yönetebiliyor ve başka ilanlara talep gönderebiliyor.

İleride iOS tarafı ayrıca test edilebilir. Play Store için de debug imza yerine
ayrı bir release imzası hazırlanması gerekir.
