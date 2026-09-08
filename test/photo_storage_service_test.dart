import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/services/photo_storage_service.dart';

void main() {
  group('PhotoStorageService', () {
    test('her fotoğraf yüklemesi için benzersiz dosya yolu üretir', () {
      final firstPath = PhotoStorageService.listingPhotoPath(
        ownerId: 'owner-1',
        listingId: 'listing-1',
        extension: 'jpg',
        uploadedAt: DateTime(2026, 9, 8, 10),
      );
      final secondPath = PhotoStorageService.listingPhotoPath(
        ownerId: 'owner-1',
        listingId: 'listing-1',
        extension: 'jpg',
        uploadedAt: DateTime(2026, 9, 8, 10, 0, 0, 1),
      );

      expect(firstPath, isNot(secondPath));
      expect(firstPath, startsWith('listing_photos/owner-1/listing-1-'));
      expect(firstPath, endsWith('.jpg'));
    });

    test('uzun veya beklenmeyen dosya uzantısını güvenli hale getirir', () {
      final path = PhotoStorageService.listingPhotoPath(
        ownerId: 'owner-1',
        listingId: 'listing-1',
        extension: 'jpegphoto',
        uploadedAt: DateTime(2026, 9, 8),
      );

      expect(path, endsWith('.jpg'));
    });
  });
}
