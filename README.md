# Sıfır Atık

Sıfır Atık, kullanıcıların kullanmadığı ama değerlendirilebilir durumda olan
atıkları ilan olarak paylaşabilmesi için geliştirdiğim bir Flutter mobil
uygulamasıdır. Uygulamada amaç, karton, cam, elektronik parça gibi atıkların
ihtiyacı olan kişiler tarafından daha kolay bulunabilmesini sağlamaktır.

## Bu Projedeki Odak Noktalarım

Bu projede daha önce kullandığım form doğrulama, durum yönetimi ve sayfalar
arası geçiş yapılarını pekiştirdim. Bunun yanında responsive arayüz, Material 3
tasarımı, SVG görsel kullanımı ve widget testleri üzerine çalıştım.

- Farklı ekran genişliklerine uyum sağlayan arayüzler geliştirdim
- Material 3 tema yapısını ve hazır bileşenleri kullandım
- Arama ve kategori filtrelerinin durumunu yönettim
- SVG görselleri Flutter arayüzüne entegre ettim
- Widget testleriyle kullanıcı etkileşimlerini kontrol ettim
- Aynı Flutter kodunu Android ve iOS ortamları için yapılandırdım
- Firebase Firestore ile ilan ve talep verilerini kullanıcıya göre ayırdım
- Firebase Storage için ilan fotoğrafı yükleme yapısını ekledim

## Uygulamada Neler Var?

- Material 3 uyumlu, responsive giriş ekranı
- Firebase Authentication ile e-posta/şifre girişi ve kayıt olma
- Şifre görünürlüğü ve şifre güç göstergesi
- Beni hatırla seçeneği
- Google ile giriş akışı
- Giriş sırasında loading durumu ve hata bildirimi
- Atık ilanı verme ve ilanları görme seçeneklerini sunan ana ekran taslağı
- Doğrulamalı atık ilanı oluşturma formu
- İlan oluştururken galeriden veya kameradan fotoğraf seçme
- Arama ve kategori filtreleri içeren ilan listesi
- İlan detay ekranı ve ilgi/talep gönderme akışı
- Profilim, İlanlarım ve Taleplerim sayfaları
- İlan sahibinin kendi ilanlarını düzenleyebilmesi ve silebilmesi
- İlan sahibinin gelen talepleri kabul veya reddedebilmesi
- Kullanıcının gönderdiği taleplerin durumunu takip edebilmesi

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

Uygulama şu anda geliştirme aşamasındadır. İlan oluşturma, ilan listeleme,
talep gönderme, talepleri takip etme ve ilanları düzenleme/silme akışlarını
Firestore ile bağladım. Firestore boş olduğunda ekranda örnek ilanlar görünmeye
devam eder; yeni ilanlar ve talepler ise giriş yapan kullanıcı üzerinden ilgili
koleksiyonlara kaydedilir.

E-posta/şifre, kayıt olma, şifre sıfırlama ve Google ile giriş işlemlerini
Firebase Authentication servisine bağladım. Bu akışların çalışması için Firebase
Console üzerinden Email/Password ve Google giriş sağlayıcılarının açık olması
gerekir.

Fotoğraf yükleme tarafında uygulama galeriden veya kameradan görsel seçebiliyor.
Görselin Firebase Storage'a yüklenebilmesi için Firebase Console üzerinden
Storage servisinin başlatılmış olması gerekir.
