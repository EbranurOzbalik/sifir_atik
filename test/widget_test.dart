import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/main.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/screens/create_listing_page.dart';
import 'package:sifir_atik/screens/home_page.dart';

void main() {
  testWidgets('login page shows its primary controls', (tester) async {
    await tester.pumpWidget(const SifirAtikApp());

    expect(find.text('Sıfır Atık'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Google ile Giriş Yap'), findsOneWidget);
    expect(find.text('Beni Hatırla'), findsOneWidget);
    expect(find.text('Şifremi Unuttum?'), findsOneWidget);
    expect(find.bySemanticsLabel('Sıfır atık görseli'), findsOneWidget);
  });

  testWidgets('password strength updates while typing', (tester) async {
    await tester.pumpWidget(const SifirAtikApp());

    final passwordField = find.byType(TextFormField).at(1);
    await tester.enterText(passwordField, 'GucluSifre123!');
    await tester.pump();

    expect(find.text('Güçlü'), findsOneWidget);
  });

  testWidgets('login shows firebase warning when auth is not ready', (
    tester,
  ) async {
    await tester.pumpWidget(const SifirAtikApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'kullanici@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Guclu123!');
    await tester.ensureVisible(find.text('Giriş Yap'));
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('Firebase bağlantısı hazır değil.'), findsOneWidget);
  });

  testWidgets('home action opens the create listing screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('Atık İlanı Ver'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni ilan oluştur'), findsOneWidget);
  });

  testWidgets('create listing requires amount and submits draft', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('Atık İlanı Ver'));
    await tester.pumpAndSettle();

    expect(find.text('Miktar'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Karton Kutular');
    await tester.tap(find.text('Kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kağıt').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '10 kg');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Temiz ve katlanmış kutular.',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'Ortahisar');
    await tester.ensureVisible(find.text('İlanı Oluştur'));
    await tester.tap(find.text('İlanı Oluştur'));
    await tester.pump();

    expect(find.text('İlan taslak olarak kaldı.'), findsOneWidget);
  });

  testWidgets('edit listing form opens with listing values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CreateListingPage(listing: sampleListings.first)),
    );

    expect(find.text('İlanı Düzenle'), findsOneWidget);
    expect(find.text('İlan bilgilerini düzenle'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsOneWidget);
    expect(find.text('10 kg'), findsOneWidget);
    expect(find.text('Değişiklikleri Kaydet'), findsOneWidget);
  });

  testWidgets('home action opens the listings screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlanları Gör'));
    await tester.pumpAndSettle();

    expect(find.text('İlanlarda ara'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsOneWidget);
  });

  testWidgets('home action opens profile screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.byTooltip('Profilim'));
    await tester.pumpAndSettle();

    expect(find.text('Profilim'), findsWidgets);
    expect(find.text('İlanlarım'), findsOneWidget);
    expect(find.text('Taleplerim'), findsOneWidget);
    expect(find.text('Çıkış Yap'), findsOneWidget);
  });

  testWidgets('home actions open my listings and requests screens', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.ensureVisible(find.text('İlanlarım'));
    await tester.tap(find.text('İlanlarım'));
    await tester.pumpAndSettle();
    expect(find.text('Giriş bulunamadı'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Taleplerim'));
    await tester.tap(find.text('Taleplerim'));
    await tester.pumpAndSettle();
    expect(
      find.text('Taleplerinizi görmek için giriş yapmalısınız.'),
      findsOneWidget,
    );
  });

  testWidgets('listing detail does not mark unsaved interest as sent', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlanları Gör'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temiz karton kutular'));
    await tester.pumpAndSettle();

    expect(find.text('İlan Detayı'), findsOneWidget);
    expect(find.text('10 kg'), findsWidgets);
    expect(find.text('Açıklama'), findsOneWidget);

    await tester.tap(find.text('İlgileniyorum'));
    await tester.pump();

    expect(find.text('Talep İletildi'), findsNothing);
    expect(find.text('Talep durumu: Beklemede'), findsNothing);
    expect(find.text('Talep şu anda gönderilemedi.'), findsOneWidget);
  });

  testWidgets('listings can be searched and filtered', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlanları Gör'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'cam');
    await tester.pump();

    expect(find.text('Cam kavanoz ve şişeler'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsNothing);

    await tester.tap(find.byTooltip('Aramayı temizle'));
    await tester.pump();
    await tester.tap(find.text('Plastik'));
    await tester.pump();

    expect(find.text('Uygun ilan bulunamadı.'), findsOneWidget);
  });
}
