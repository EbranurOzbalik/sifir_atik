import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/main.dart';
import 'package:sifir_atik/screens/home_page.dart';

void main() {
  testWidgets('login page shows its primary controls', (tester) async {
    await tester.pumpWidget(const SifirAtikApp());

    expect(find.text('Sıfır Atık'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Google ile Giriş Yap'), findsOneWidget);
    expect(find.text('Beni Hatırla'), findsOneWidget);
    expect(find.text('Şifremi Unuttum?'), findsOneWidget);
    expect(find.byIcon(Icons.recycling), findsOneWidget);
  });

  testWidgets('password strength updates while typing', (tester) async {
    await tester.pumpWidget(const SifirAtikApp());

    final passwordField = find.byType(TextFormField).at(1);
    await tester.enterText(passwordField, 'GucluSifre123!');
    await tester.pump();

    expect(find.text('Güçlü'), findsOneWidget);
  });

  testWidgets('valid login opens the initial home screen', (tester) async {
    await tester.pumpWidget(const SifirAtikApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'kullanici@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Guclu123!');
    await tester.ensureVisible(find.text('Giriş Yap'));
    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.pumpAndSettle();

    expect(find.text('Atık İlanı Ver'), findsOneWidget);
    expect(find.text('İlanları Gör'), findsOneWidget);
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

    expect(find.text('İlan taslağı hazırlandı.'), findsOneWidget);
  });

  testWidgets('home action opens the listings screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlanları Gör'));
    await tester.pumpAndSettle();

    expect(find.text('İlanlarda ara'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsOneWidget);
  });

  testWidgets('listing detail lets users send interest', (tester) async {
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

    expect(find.text('Talep İletildi'), findsOneWidget);
    expect(find.text('Talebiniz ilan sahibine iletildi.'), findsOneWidget);
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
