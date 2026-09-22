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
    });
  });
}
