import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/models/user_profile.dart';
import 'package:sifir_atik/screens/edit_profile_page.dart';
import 'package:sifir_atik/services/user_profile_repository.dart';

void main() {
  testWidgets('profil bilgilerini düzenleyip kaydeder', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repository = UserProfileRepository(firestore: firestore);

    await repository.createProfileIfMissing(
      uid: 'user-1',
      displayName: 'Eski Kullanıcı',
      email: 'kullanici@example.com',
      accountType: AccountType.individual,
      city: 'Trabzon',
    );
    final profile = (await repository.getProfile('user-1'))!;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EditProfilePage(
                        profile: profile,
                        repository: repository,
                        updateAuthDisplayName: (_) async {},
                      ),
                    ),
                  );
                },
                child: const Text('Profili aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Profili aç'));
    await tester.pumpAndSettle();

    expect(find.text('Bireysel hesap'), findsOneWidget);
    expect(find.text('kullanici@example.com'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Yeni Kullanıcı');
    await tester.enterText(find.byType(TextFormField).at(1), 'Riz');
    await tester.pump();
    await tester.tap(find.text('Rize').last);
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Profili aç'), findsOneWidget);

    final updatedProfile = await repository.getProfile('user-1');
    expect(updatedProfile!.displayName, 'Yeni Kullanıcı');
    expect(updatedProfile.city, 'Rize');
    expect(updatedProfile.accountType, AccountType.individual);
  });
}
