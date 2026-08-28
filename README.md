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

Uygulama geliştirme aşamasındadır. İlan oluşturma, ilan listeleme ve Firestore
entegrasyonu henüz eklenmemiştir. Google ile giriş arayüzü hazırdır; gerçek
Firebase Authentication bağlantısı sonraki aşamada tamamlanacaktır.
