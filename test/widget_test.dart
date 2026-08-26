import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/main.dart';

void main() {
  testWidgets('login page shows its primary controls', (tester) async {
    await tester.pumpWidget(const SifirAtikApp());

    expect(find.text('Sıfır Atık'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
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
}
