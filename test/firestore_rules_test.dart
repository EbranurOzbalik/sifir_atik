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
  });
}
