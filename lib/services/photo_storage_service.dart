import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

class PhotoStorageService {
  const PhotoStorageService({FirebaseStorage? storage}) : _storage = storage;

  final FirebaseStorage? _storage;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  static String listingPhotoPath({
    required String ownerId,
    required String listingId,
    required String extension,
    DateTime? uploadedAt,
  }) {
    final safeExtension = extension.toLowerCase().length <= 5
        ? extension.toLowerCase()
        : 'jpg';
    final timestamp = (uploadedAt ?? DateTime.now()).microsecondsSinceEpoch;

    return 'listing_photos/$ownerId/$listingId-$timestamp.$safeExtension';
  }

  Future<String?> uploadListingPhoto({
    required File photo,
    required String ownerId,
    required String listingId,
  }) async {
    if (!_isFirebaseReady || ownerId.isEmpty || listingId.isEmpty) return null;

    final extension = photo.path.split('.').last.toLowerCase();
    final photoPath = listingPhotoPath(
      ownerId: ownerId,
      listingId: listingId,
      extension: extension,
    );
    final metadata = SettableMetadata(
      contentType: lookupMimeType(photo.path) ?? 'image/jpeg',
    );

    final snapshot = await _bucket.ref(photoPath).putFile(photo, metadata);

    return snapshot.ref.getDownloadURL();
  }

  Future<bool> deleteListingPhoto(String? imageUrl) async {
    if (!_isFirebaseReady || imageUrl == null || imageUrl.isEmpty) {
      return true;
    }

    try {
      await _bucket.refFromURL(imageUrl).delete();
      return true;
    } on FirebaseException catch (error) {
      return error.code == 'object-not-found';
    } catch (_) {
      return false;
    }
  }
}
