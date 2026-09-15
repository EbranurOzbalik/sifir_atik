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
