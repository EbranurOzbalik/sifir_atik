import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_request.dart';

class ListingRepository {
  const ListingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<Listing>> watchListings() async* {
    if (!_isFirebaseReady) {
      yield sampleListings;
      return;
    }

    try {
      final query = _db
          .collection('listings')
          .orderBy('createdAt', descending: true);

      await for (final snapshot in query.snapshots()) {
        final listings = snapshot.docs
            .map(Listing.fromFirestore)
            .where((listing) => listing.title.isNotEmpty)
            .toList();

        yield listings.isEmpty ? sampleListings : listings;
      }
    } catch (_) {
      yield sampleListings;
    }
  }

  Stream<List<Listing>> watchMyListings(String userId) async* {
    if (!_isFirebaseReady || userId.isEmpty) {
      yield const [];
      return;
    }

    try {
      final query = _db
          .collection('listings')
          .where('ownerId', isEqualTo: userId);

      await for (final snapshot in query.snapshots()) {
        final listings =
            snapshot.docs
                .map(Listing.fromFirestore)
                .where((listing) => listing.title.isNotEmpty)
                .toList()
              ..sort(
                (first, second) => second.createdAt.compareTo(first.createdAt),
              );

        yield listings;
      }
    } catch (_) {
      yield const [];
    }
  }

  Stream<List<ListingRequest>> watchRequestsByRequester(String userId) async* {
    if (!_isFirebaseReady || userId.isEmpty) {
      yield const [];
      return;
    }

    try {
      final query = _db
          .collection('listingRequests')
          .where('requesterId', isEqualTo: userId);

      await for (final snapshot in query.snapshots()) {
        final requests =
            snapshot.docs
                .map(ListingRequest.fromFirestore)
                .where((request) => request.listingId.isNotEmpty)
                .toList()
              ..sort(
                (first, second) => second.createdAt.compareTo(first.createdAt),
              );

        yield requests;
      }
    } catch (_) {
      yield const [];
    }
  }

  Stream<List<ListingRequest>> watchRequestsByListingOwner(
    String ownerId,
  ) async* {
    if (!_isFirebaseReady || ownerId.isEmpty) {
      yield const [];
      return;
    }

    try {
      final query = _db
          .collection('listingRequests')
          .where('listingOwnerId', isEqualTo: ownerId);

      await for (final snapshot in query.snapshots()) {
        final requests =
            snapshot.docs
                .map(ListingRequest.fromFirestore)
                .where((request) => request.listingId.isNotEmpty)
                .toList()
              ..sort(
                (first, second) => second.createdAt.compareTo(first.createdAt),
              );

        yield requests;
      }
    } catch (_) {
      yield const [];
    }
  }

  Future<bool> addListing(Listing listing) async {
    if (!_isFirebaseReady) return false;

    try {
      await _db
          .collection('listings')
          .doc(listing.id)
          .set(listing.toFirestore());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateListing(Listing listing) async {
    if (!_isFirebaseReady || listing.id.isEmpty) return false;

    try {
      final batch = _db.batch();
      final listingRef = _db.collection('listings').doc(listing.id);
      batch.update(listingRef, {
        'title': listing.title,
        'category': listing.category,
        'location': listing.location,
        'amount': listing.amount,
        'description': listing.description,
        'imageAsset': listing.imageAsset,
        if (listing.imageUrl != null && listing.imageUrl!.isNotEmpty)
          'imageUrl': listing.imageUrl,
      });

      final requestSnapshot = await _db
          .collection('listingRequests')
          .where('listingId', isEqualTo: listing.id)
          .get();

      for (final requestDoc in requestSnapshot.docs) {
        batch.update(requestDoc.reference, {
          'listingTitle': listing.title,
          'listingAmount': listing.amount,
          'listingLocation': listing.location,
        });
      }

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteListing(Listing listing) async {
    if (!_isFirebaseReady || listing.id.isEmpty) return false;

    try {
      final batch = _db.batch();
      final requestSnapshot = await _db
          .collection('listingRequests')
          .where('listingId', isEqualTo: listing.id)
          .get();

      for (final requestDoc in requestSnapshot.docs) {
        batch.delete(requestDoc.reference);
      }

      batch.delete(_db.collection('listings').doc(listing.id));
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addRequest(ListingRequest request) async {
    if (!_isFirebaseReady) return false;

    try {
      await _db
          .collection('listingRequests')
          .doc(request.id)
          .set(request.toFirestore());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    if (!_isFirebaseReady || requestId.isEmpty) return false;

    try {
      await _db.collection('listingRequests').doc(requestId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateRequestStatus(
    String requestId,
    ListingRequestStatus status,
  ) async {
    if (!_isFirebaseReady || requestId.isEmpty) return false;

    try {
      await _db.collection('listingRequests').doc(requestId).update({
        'status': status.name,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
