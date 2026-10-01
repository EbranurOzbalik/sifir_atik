import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_rating.dart';
import 'package:sifir_atik/models/listing_report.dart';
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
          contactInfo: '0555 999 88 77',
        );

        final isUpdated = await repository.updateListing(updatedListing);
        final requests = await repository
            .watchRequestsByRequester('user-1')
            .first;

        expect(isUpdated, isTrue);
        expect(requests.single.listingTitle, 'Temiz karton koliler');
        expect(requests.single.listingAmount, '12 kg');
        expect(requests.single.listingLocation, 'Ortahisar');
        expect(requests.single.ownerContactInfo, '0555 999 88 77');
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

    test(
      'talep kabul edilince ilan ayrılır ve diğer talepler reddedilir',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = ListingRepository(firestore: firestore);
        final request = _request(id: 'request-1');
        final otherRequest = _request(id: 'request-2', requesterId: 'user-2');

        await repository.addListing(_listing());
        await repository.addRequest(request);
        await repository.addRequest(otherRequest);

        final isUpdated = await repository.updateRequestStatus(
          request.id,
          ListingRequestStatus.accepted,
        );
        final ownerRequests = await repository
            .watchRequestsByListingOwner('owner-1')
            .first;
        final listings = await repository.watchMyListings('owner-1').first;

        expect(isUpdated, isTrue);
        expect(
          ownerRequests.singleWhere((item) => item.id == request.id).status,
          ListingRequestStatus.accepted,
        );
        expect(
          ownerRequests
              .singleWhere((item) => item.id == otherRequest.id)
              .status,
          ListingRequestStatus.rejected,
        );
        expect(listings.single.status, ListingStatus.reserved);
        expect(listings.single.acceptedRequestId, request.id);
      },
    );

    test(
      'teslimat tamamlanınca ilan, talep ve katkı birlikte güncellenir',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = ListingRepository(firestore: firestore);
        final listing = _listing();
        final request = _request();

        await repository.addListing(listing);
        await repository.addRequest(request);
        await repository.updateRequestStatus(
          request.id,
          ListingRequestStatus.accepted,
        );

        final isCompleted = await repository.completeListing(
          listingId: listing.id,
          requestId: request.id,
        );
        final listings = await repository.watchMyListings('owner-1').first;
        final requests = await repository
            .watchRequestsByRequester('user-1')
            .first;
        final contribution = await repository
            .watchContributionSummary('owner-1')
            .first;

        expect(isCompleted, isTrue);
        expect(listings.single.status, ListingStatus.completed);
        expect(listings.single.completedAt, isNotNull);
        expect(requests.single.status, ListingRequestStatus.completed);
        expect(contribution.completedCount, 1);
        expect(contribution.totalKilograms, 10);
      },
    );

    test('teslimat değerlendirmesi güven puanına eklenir', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ListingRepository(firestore: firestore);
      final rating = ListingRating(
        id: 'request-1',
        requestId: 'request-1',
        listingId: 'listing-1',
        listingTitle: 'Karton kutular',
        ratedUserId: 'owner-1',
        raterUserId: 'user-1',
        raterName: 'Zeynep',
        score: 5,
        comment: 'Teslimat zamanında tamamlandı.',
        createdAt: DateTime(2026, 10),
      );

      final isSaved = await repository.addRating(rating);
      final savedRating = await repository
          .watchRatingForRequest(rating.requestId)
          .first;
      final summary = await repository.watchRatingSummary('owner-1').first;
      final isSavedAgain = await repository.addRating(rating);

      expect(isSaved, isTrue);
      expect(savedRating?.score, 5);
      expect(savedRating?.comment, 'Teslimat zamanında tamamlandı.');
      expect(summary.count, 1);
      expect(summary.average, 5);
      expect(isSavedAgain, isFalse);
    });

    test('ilan kullanıcıya özel kaydedilip kaldırılabilir', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ListingRepository(firestore: firestore);

      final isSaved = await repository.setListingSaved(
        userId: 'user-1',
        listingId: 'listing-1',
        isSaved: true,
      );
      final savedIds = await repository.watchSavedListingIds('user-1').first;

      expect(isSaved, isTrue);
      expect(savedIds, {'listing-1'});

      final isRemoved = await repository.setListingSaved(
        userId: 'user-1',
        listingId: 'listing-1',
        isSaved: false,
      );
      final remainingIds = await repository
          .watchSavedListingIds('user-1')
          .first;

      expect(isRemoved, isTrue);
      expect(remainingIds, isEmpty);
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

    test('açık ilan bildirimlerini listeler', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ListingRepository(firestore: firestore);
      final report = _report(id: 'report-1');

      final isSaved = await repository.addReport(report);
      final reports = await repository.watchOpenReports().first;

      expect(isSaved, isTrue);
      expect(reports, hasLength(1));
      expect(reports.single.reason, 'Yanlış kategori');
    });

    test('bildirim incelenince açık listeden çıkar', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ListingRepository(firestore: firestore);
      final report = _report(id: 'report-1');

      await repository.addReport(report);
      final isResolved = await repository.resolveReport(report.id);
      final reports = await repository.watchOpenReports().first;

      expect(isResolved, isTrue);
      expect(reports, isEmpty);
    });

    test('moderatör ilanı kaldırınca bağlı kayıtlar temizlenir', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ListingRepository(firestore: firestore);
      final listing = _listing(id: 'listing-1');

      await repository.addListing(listing);
      await repository.addRequest(
        _request(
          id: 'request-1',
          listingId: listing.id,
          listingOwnerId: listing.ownerId,
        ),
      );
      await repository.addReport(
        _report(
          id: 'report-1',
          listingId: listing.id,
          listingOwnerId: listing.ownerId,
        ),
      );

      final isDeleted = await repository.deleteReportedListing(listing.id);
      final listings = await repository.watchMyListings(listing.ownerId).first;
      final requests = await repository
          .watchRequestsByRequester('user-1')
          .first;
      final reports = await repository.watchOpenReports().first;

      expect(isDeleted, isTrue);
      expect(listings, isEmpty);
      expect(requests, isEmpty);
      expect(reports, isEmpty);
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
    contactInfo: '0555 111 22 33',
    imageUrl: imageUrl,
  );
}

ListingRequest _request({
  String id = 'request-1',
  String listingId = 'listing-1',
  String listingOwnerId = 'owner-1',
  String listingTitle = 'Temiz karton kutular',
  String requesterId = 'user-1',
}) {
  return ListingRequest(
    id: id,
    listingId: listingId,
    listingOwnerId: listingOwnerId,
    listingTitle: listingTitle,
    listingAmount: '10 kg',
    listingLocation: 'Trabzon / Ortahisar',
    ownerContactInfo: '0555 111 22 33',
    requesterId: requesterId,
    requesterName: 'Zeynep',
    status: ListingRequestStatus.pending,
    createdAt: DateTime(2026, 9, 8),
  );
}

ListingReport _report({
  String id = 'report-1',
  String listingId = 'listing-1',
  String listingOwnerId = 'owner-1',
}) {
  return ListingReport(
    id: id,
    listingId: listingId,
    listingOwnerId: listingOwnerId,
    listingTitle: 'Temiz karton kutular',
    listingAmount: '10 kg',
    listingLocation: 'Trabzon / Ortahisar',
    reporterId: 'user-1',
    reporterName: 'Zeynep',
    reason: 'Yanlış kategori',
    status: ListingReportStatus.open,
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
