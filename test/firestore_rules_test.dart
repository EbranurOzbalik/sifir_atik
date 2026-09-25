import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firestore.rules', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test(
      'ilan oluştururken kullanıcı kendi ownerId bilgisini kullanmalıdır',
      () {
        expect(
          rules,
          contains('request.auth.uid == request.resource.data.ownerId'),
        );
      },
    );

    test('ilan güncellenirken ownerId başka kullanıcıya aktarılamaz', () {
      expect(
        rules,
        contains('request.resource.data.ownerId == resource.data.ownerId'),
      );
    });

    test('moderatör rolü users koleksiyonundan kontrol edilir', () {
      expect(rules, contains('function isModerator()'));
      expect(rules, contains('match /users/{userId}'));
      expect(rules, contains('request.auth.uid == userId'));
      expect(rules, contains("data.role == 'moderator'"));
      expect(rules, contains('data.isModerator == true'));
    });

    test('kullanıcı kendi profilinde moderatör yetkisi oluşturamaz', () {
      expect(rules, contains("request.resource.data.role == 'user'"));
      expect(
        rules,
        contains("!request.resource.data.keys().hasAny(['isModerator'])"),
      );
      expect(rules, contains("accountType in ['individual', 'organization']"));
      expect(
        rules,
        contains('request.resource.data.isOrganizationVerified == false'),
      );
      expect(
        rules,
        contains(
          "request.resource.data.accountType == resource.data.get('accountType', '')",
        ),
      );
    });

    test('kurumsal ilan rozeti kullanıcı profiliyle eşleşmelidir', () {
      expect(rules, contains('request.resource.data.ownerAccountType =='));
      expect(rules, contains('data.isOrganizationVerified == true'));
    });

    test('bildirim ve cihaz kayıtları kullanıcıya özel tutulur', () {
      expect(rules, contains('match /devices/{deviceId}'));
      expect(rules, contains('match /notifications/{notificationId}'));
      expect(rules, contains(".hasOnly(['isRead'])"));
      expect(rules, contains('allow create: if false'));
    });

    test('ilan bildirimleri yalnızca giriş yapan kullanıcıyla oluşturulur', () {
      expect(rules, contains('match /listingReports/{reportId}'));
      expect(
        rules,
        contains('request.auth.uid == request.resource.data.reporterId'),
      );
      expect(
        rules,
        contains(
          'request.resource.data.reporterId != request.resource.data.listingOwnerId',
        ),
      );
    });
  });
}
