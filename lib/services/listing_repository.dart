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

  Future<bool> addListing(Listing listing) async {
    if (!_isFirebaseReady) return false;

    try {
      await _db.collection('listings').add(listing.toFirestore());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addRequest(ListingRequest request) async {
    if (!_isFirebaseReady) return false;

    try {
      await _db.collection('listingRequests').add(request.toFirestore());
      return true;
    } catch (_) {
      return false;
    }
  }
}
