# Sıfır Atık

Sıfır Atık, kullanıcıların kullanmadığı ama değerlendirilebilir durumda olan
atıkları ilan olarak paylaşabilmesi için geliştirdiğim bir Flutter mobil
uygulamasıdır. Uygulamada amaç, karton, cam, elektronik parça gibi atıkların
ihtiyacı olan kişiler tarafından daha kolay bulunabilmesini sağlamaktır.

## Bu Projede Neler Üzerinde Çalıştım?

Bu projede hem Flutter tarafında pratik yapmak hem de gerçek verilerle çalışan
bir uygulama akışı kurmak istedim. Daha önce kullandığım form doğrulama, sayfalar
arası geçiş ve durum yönetimi yapılarını bu projede tekrar kullandım. Sonrasında
Firebase bağlantısını ekleyerek ilan ve talep bilgilerinin uygulamada kalıcı
olmasını sağlamaya çalıştım.

- Farklı ekran genişliklerine uyum sağlayan arayüzler geliştirdim
- Material 3 tema yapısını ve hazır bileşenleri kullandım
- Arama ve kategori filtrelerinin durumunu yönettim
- SVG görselleri Flutter arayüzüne entegre ettim
- Widget testleriyle kullanıcı etkileşimlerini kontrol ettim
- Firebase Firestore ile ilan ve talep verilerini kaydettim
- Firebase Storage ile ilanlara fotoğraf ekleme kısmını yaptım
- Giriş yapan kullanıcı için basit bir oturum kontrolü ekledim

## Uygulamada Bulunan Özellikler

### Giriş ve kullanıcı işlemleri

- E-posta/şifre ile giriş yapma ve kayıt olma
- Google ile giriş akışı
- Şifre görünürlüğü, şifre güç göstergesi ve şifre sıfırlama
- Beni hatırla seçeneği ve uygulama açılışında oturum kontrolü
- Profilim sayfası ve çıkış yapma

### İlan işlemleri

- Atık ilanı oluşturma, listeleme ve detay ekranı
- Galeriden veya kameradan ilan fotoğrafı seçme
- İlan fotoğrafını güncelleme veya kaldırma
- Arama ve kategori filtreleriyle ilanları bulma
- Kullanıcının kendi ilanlarını İlanlarım sayfasında görmesi
- İlan sahibinin kendi ilanlarını düzenleyebilmesi ve silebilmesi

### Talep işlemleri

- Kullanıcının ilgilendiği ilana talep göndermesi
- Gönderilen taleplerin Taleplerim sayfasında görünmesi
- İlan sahibinin gelen talepleri kabul veya reddetmesi
- Talep durumunun beklemede, kabul edildi veya reddedildi olarak takip edilmesi
- İlan listesi tekrar açıldığında talep durumlarının güncel kalması

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

## Projeyi Çalıştırma

Flutter SDK'nın kurulu olduğundan emin olduktan sonra Android emülatörde:

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

Projeyi şu an Android emülatör üzerinden test ediyorum. Kullanıcı giriş yaptıktan
sonra ilan oluşturabiliyor, fotoğraf ekleyebiliyor, kendi ilanlarını düzenleyip
silebiliyor ve başka ilanlara talep gönderebiliyor.

Firestore'da henüz ilan yoksa uygulamanın tamamen boş görünmemesi için birkaç
örnek ilan gösteriyorum. Gerçek ilan eklendiğinde liste Firebase'deki verilerle
güncelleniyor.

Şimdilik temel akışları tamamladım. Bundan sonra özellikle farklı kullanıcılarla
talep gönderme/kabul etme senaryosunu biraz daha test edip arayüzde küçük
düzenlemeler yapmayı düşünüyorum.
