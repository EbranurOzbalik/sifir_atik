import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/photo_storage_service.dart';

void main() {
  group('ListingRepository', () {
    test('ilan ekleme ve listeleme akışını kaydeder', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ListingRepository(firestore: firestore);
      final listing = _listing(id: 'listing-1', title: 'Karton kutular');

      final isSaved = await repository.addListing(listing);
      final listings = await repository.watchListings().first;

      expect(isSaved, isTrue);
      expect(listings, hasLength(1));
      expect(listings.first.title, 'Karton kutular');
      expect(listings.first.ownerId, 'owner-1');
    });

    test(
      'ilan düzenlenince bağlı taleplerdeki ilan bilgileri güncellenir',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = ListingRepository(firestore: firestore);
        final listing = _listing(id: 'listing-1', title: 'Karton kutular');
        final request = _request(
          id: 'request-1',
          listingId: listing.id,
          listingOwnerId: listing.ownerId,
          listingTitle: listing.title,
        );

        await repository.addListing(listing);
        await repository.addRequest(request);

        final updatedListing = listing.copyWith(
          title: 'Temiz karton koliler',
          amount: '12 kg',
          location: 'Ortahisar',
        );

        final isUpdated = await repository.updateListing(updatedListing);
        final requests = await repository
            .watchRequestsByRequester('user-1')
            .first;

        expect(isUpdated, isTrue);
        expect(requests.single.listingTitle, 'Temiz karton koliler');
        expect(requests.single.listingAmount, '12 kg');
        expect(requests.single.listingLocation, 'Ortahisar');
      },
    );

    test('ilan silinince ilana bağlı talepler de silinir', () async {
      final firestore = FakeFirebaseFirestore();
      final photoStorage = _FakePhotoStorageService();
      final repository = ListingRepository(
        firestore: firestore,
        photoStorageService: photoStorage,
      );
      final listing = _listing(
        id: 'listing-1',
        imageUrl: 'https://example.com/listing.jpg',
      );

      await repository.addListing(listing);
      await repository.addRequest(
        _request(
          id: 'request-1',
          listingId: listing.id,
          listingOwnerId: listing.ownerId,
        ),
      );

      final isDeleted = await repository.deleteListing(listing);
      final listings = await repository.watchMyListings('owner-1').first;
      final requests = await repository
          .watchRequestsByRequester('user-1')
          .first;

      expect(isDeleted, isTrue);
      expect(listings, isEmpty);
      expect(requests, isEmpty);
      expect(photoStorage.deletedUrl, listing.imageUrl);
    });

    test('talep durumu kabul veya ret olarak güncellenebilir', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ListingRepository(firestore: firestore);
      final request = _request(id: 'request-1');

      await repository.addRequest(request);

      final isUpdated = await repository.updateRequestStatus(
        request.id,
        ListingRequestStatus.accepted,
      );
      final ownerRequests = await repository
          .watchRequestsByListingOwner('owner-1')
          .first;

      expect(isUpdated, isTrue);
      expect(ownerRequests.single.status, ListingRequestStatus.accepted);
    });

    test('talep silinince kullanıcının taleplerinden kaldırılır', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ListingRepository(firestore: firestore);
      final request = _request(id: 'request-1');

      await repository.addRequest(request);

      final isDeleted = await repository.deleteRequest(request.id);
      final requests = await repository
          .watchRequestsByRequester('user-1')
          .first;

      expect(isDeleted, isTrue);
      expect(requests, isEmpty);
    });
  });
}

Listing _listing({
  String id = 'listing-1',
  String title = 'Temiz karton kutular',
  String amount = '10 kg',
  String location = 'Trabzon / Ortahisar',
  String? imageUrl,
}) {
  return Listing(
    id: id,
    title: title,
    category: 'Kağıt',
    location: location,
    amount: amount,
    description: 'Temiz ve kullanılabilir durumda.',
    ownerId: 'owner-1',
    ownerName: 'Ebranur',
    createdAt: DateTime(2026, 9, 8),
    imageAsset: 'assets/images/cardboard_boxes.svg',
    imageUrl: imageUrl,
  );
}

ListingRequest _request({
  String id = 'request-1',
  String listingId = 'listing-1',
  String listingOwnerId = 'owner-1',
  String listingTitle = 'Temiz karton kutular',
}) {
  return ListingRequest(
    id: id,
    listingId: listingId,
    listingOwnerId: listingOwnerId,
    listingTitle: listingTitle,
    listingAmount: '10 kg',
    listingLocation: 'Trabzon / Ortahisar',
    requesterId: 'user-1',
    requesterName: 'Zeynep',
    status: ListingRequestStatus.pending,
    createdAt: DateTime(2026, 9, 8),
  );
}

class _FakePhotoStorageService extends PhotoStorageService {
  String? deletedUrl;

  @override
  Future<bool> deleteListingPhoto(String? imageUrl) async {
    deletedUrl = imageUrl;
    return true;
  }
}
