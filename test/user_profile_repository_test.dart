import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/models/user_profile.dart';
import 'package:sifir_atik/services/user_profile_repository.dart';

void main() {
  group('UserProfileRepository', () {
    test('bireysel kullanıcı profilini kaydeder', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = UserProfileRepository(firestore: firestore);

      await repository.createProfileIfMissing(
        uid: 'user-1',
        displayName: 'Ebranur Özbalık',
        email: 'ebranur@example.com',
        accountType: AccountType.individual,
      );

      final profile = await repository.getProfile('user-1');

      expect(profile, isNotNull);
      expect(profile!.displayName, 'Ebranur Özbalık');
      expect(profile.accountType, AccountType.individual);
    });

    test('var olan kurum profilinin türünü değiştirmez', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = UserProfileRepository(firestore: firestore);

      await repository.createProfileIfMissing(
        uid: 'organization-1',
        displayName: 'Yeşil Dönüşüm A.Ş.',
        email: 'iletisim@example.com',
        accountType: AccountType.organization,
        city: 'Trabzon',
        contactPersonName: 'Ebranur Özbalık',
        organizationType: OrganizationType.company,
      );
      await repository.createProfileIfMissing(
        uid: 'organization-1',
        displayName: 'Başka ad',
        email: 'baska@example.com',
        accountType: AccountType.individual,
      );

      final profile = await repository.getProfile('organization-1');

      expect(profile!.displayName, 'Yeşil Dönüşüm A.Ş.');
      expect(profile.accountType, AccountType.organization);
      expect(profile.city, 'Trabzon');
      expect(profile.contactPersonName, 'Ebranur Özbalık');
      expect(profile.organizationType, OrganizationType.company);
      expect(profile.isOrganizationVerified, isFalse);
    });

    test(
      'eski kullanıcı belgesindeki eksik profil alanlarını tamamlar',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('users').doc('legacy-user').set({
          'role': 'moderator',
        });
        final repository = UserProfileRepository(firestore: firestore);

        await repository.createProfileIfMissing(
          uid: 'legacy-user',
          displayName: 'Eski Kullanıcı',
          email: 'eski@example.com',
          accountType: AccountType.individual,
        );

        final data =
            (await firestore.collection('users').doc('legacy-user').get())
                .data()!;
        expect(data['role'], 'moderator');
        expect(data['accountType'], 'individual');
        expect(data['isOrganizationVerified'], isFalse);
      },
    );
  });
}
