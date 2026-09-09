import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/main.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/screens/create_listing_page.dart';
import 'package:sifir_atik/screens/home_page.dart';
import 'package:sifir_atik/screens/listings_page.dart';
import 'package:sifir_atik/screens/my_requests_page.dart';
import 'package:sifir_atik/services/listing_repository.dart';

void main() {
  testWidgets('login page shows its primary controls', (tester) async {
    await tester.pumpWidget(const SifirAtikApp());

    expect(find.text('Sıfır Atık'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Google ile Giriş Yap'), findsOneWidget);
    expect(find.text('Beni Hatırla'), findsOneWidget);
    expect(find.text('Şifremi Unuttum?'), findsOneWidget);
    expect(find.bySemanticsLabel('Sıfır atık görseli'), findsOneWidget);
  });

  testWidgets('password strength updates while typing', (tester) async {
    await tester.pumpWidget(const SifirAtikApp());

    final passwordField = find.byType(TextFormField).at(1);
    await tester.enterText(passwordField, 'GucluSifre123!');
    await tester.pump();

    expect(find.text('Güçlü'), findsOneWidget);
  });

  testWidgets('register action opens a separate create account form', (
    tester,
  ) async {
    await tester.pumpWidget(const SifirAtikApp());

    await tester.ensureVisible(find.text('Kayıt Ol'));
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pump();

    expect(find.text('Şifre tekrar'), findsOneWidget);
    expect(find.text('Hesap Oluştur'), findsOneWidget);
    expect(find.text('Zaten hesabın var mı?'), findsOneWidget);
  });

  testWidgets('login shows firebase warning when auth is not ready', (
    tester,
  ) async {
    await tester.pumpWidget(const SifirAtikApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'kullanici@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Guclu123!');
    await tester.ensureVisible(find.text('Giriş Yap'));
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('Firebase bağlantısı hazır değil.'), findsOneWidget);
  });

  testWidgets('home action opens the create listing screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('Atık İlanı Ver'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni ilan oluştur'), findsOneWidget);
  });

  testWidgets('create listing requires amount and submits draft', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('Atık İlanı Ver'));
    await tester.pumpAndSettle();

    expect(find.text('Miktar'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Karton Kutular');
    await tester.tap(find.text('Kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kağıt').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '10 kg');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Temiz ve katlanmış kutular.',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'Ortahisar');
    await tester.enterText(find.byType(TextFormField).at(4), '0555 111 22 33');
    await tester.ensureVisible(find.text('İlanı Oluştur'));
    await tester.tap(find.text('İlanı Oluştur'));
    await tester.pump();

    expect(find.text('İlan taslak olarak kaldı.'), findsOneWidget);
  });

  testWidgets('edit listing form opens with listing values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CreateListingPage(listing: sampleListings.first)),
    );

    expect(find.text('İlanı Düzenle'), findsOneWidget);
    expect(find.text('İlan bilgilerini düzenle'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsOneWidget);
    expect(find.text('10 kg'), findsOneWidget);
    expect(find.text('Değişiklikleri Kaydet'), findsOneWidget);
  });

  testWidgets('edit listing form can remove existing photo', (tester) async {
    final listing = sampleListings.first.copyWith(
      imageUrl: 'https://example.com/photo.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(home: CreateListingPage(listing: listing)),
    );

    expect(find.text('Mevcut fotoğraf'), findsOneWidget);

    await tester.tap(find.text('Kaldır'));
    await tester.pump();

    expect(find.text('Mevcut fotoğraf'), findsNothing);
    expect(find.text('Fotoğraf Ekle'), findsOneWidget);
  });

  test('listing copyWith can clear image url', () {
    final listing = sampleListings.first.copyWith(
      imageUrl: 'https://example.com/photo.jpg',
    );

    expect(listing.imageUrl, isNotNull);
    expect(listing.copyWith(clearImageUrl: true).imageUrl, isNull);
  });

  testWidgets('home action opens the listings screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlanları Gör'));
    await tester.pumpAndSettle();

    expect(find.text('İlanlarda ara'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsOneWidget);
  });

  testWidgets('home action opens profile screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.byTooltip('Profilim'));
    await tester.pumpAndSettle();

    expect(find.text('Profilim'), findsWidgets);
    expect(find.text('İlanlarım'), findsOneWidget);
    expect(find.text('Taleplerim'), findsOneWidget);
    expect(find.text('Çıkış Yap'), findsOneWidget);
  });

  testWidgets('home actions open my listings and requests screens', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.ensureVisible(find.text('İlanlarım'));
    await tester.tap(find.text('İlanlarım'));
    await tester.pumpAndSettle();
    expect(find.text('Giriş bulunamadı'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Taleplerim'));
    await tester.tap(find.text('Taleplerim'));
    await tester.pumpAndSettle();
    expect(
      find.text('Taleplerinizi görmek için giriş yapmalısınız.'),
      findsOneWidget,
    );
  });

  testWidgets('listing detail does not mark unsaved interest as sent', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlanları Gör'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temiz karton kutular'));
    await tester.pumpAndSettle();

    expect(find.text('İlan Detayı'), findsOneWidget);
    expect(find.text('10 kg'), findsWidgets);
    expect(find.text('Açıklama'), findsOneWidget);

    await tester.tap(find.text('İlgileniyorum'));
    await tester.pump();

    expect(find.text('Talep İletildi'), findsNothing);
    expect(find.text('Talep durumu: Beklemede'), findsNothing);
    expect(find.text('Talep şu anda gönderilemedi.'), findsOneWidget);
  });

  testWidgets('user cannot send request to their own listing', (tester) async {
    final listing = _testListing(ownerId: 'user-1');
    final repository = _FakeListingRepository(listings: [listing]);

    await tester.pumpWidget(
      MaterialApp(
        home: ListingsPage(
          repository: repository,
          currentUserId: 'user-1',
          currentUserName: 'Ebranur',
          isFirebaseReady: true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Karton denemesi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İlgileniyorum'));
    await tester.pump();

    expect(find.text('Kendi ilanınıza talep gönderemezsiniz.'), findsOneWidget);
    expect(repository.addRequestCount, 0);
    expect(find.text('Talep İletildi'), findsNothing);
  });

  testWidgets('failed request does not show sent state', (tester) async {
    final listing = _testListing(ownerId: 'owner-1');
    final repository = _FakeListingRepository(
      listings: [listing],
      shouldSaveRequest: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ListingsPage(
          repository: repository,
          currentUserId: 'user-1',
          currentUserName: 'Zeynep',
          isFirebaseReady: true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Karton denemesi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İlgileniyorum'));
    await tester.pump();

    expect(repository.addRequestCount, 1);
    expect(find.text('Talep şu anda gönderilemedi.'), findsOneWidget);
    expect(find.text('Talep İletildi'), findsNothing);
    expect(find.text('Talep durumu: Beklemede'), findsNothing);
  });

  testWidgets('request statuses are shown as pending accepted and rejected', (
    tester,
  ) async {
    final repository = _FakeListingRepository(
      requests: [
        _testRequest('request-pending', ListingRequestStatus.pending),
        _testRequest(
          'request-accepted',
          ListingRequestStatus.accepted,
          ownerContactInfo: '0555 111 22 33',
        ),
        _testRequest('request-rejected', ListingRequestStatus.rejected),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MyRequestsPage(
          repository: repository,
          currentUserId: 'user-1',
          isFirebaseReady: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Beklemede'), findsOneWidget);
    expect(find.text('Kabul edildi'), findsOneWidget);
    expect(find.text('Reddedildi'), findsOneWidget);
    expect(
      find.text('İlan sahibinin iletişimi: 0555 111 22 33'),
      findsOneWidget,
    );
  });

  testWidgets('owner contact is hidden until request is accepted', (
    tester,
  ) async {
    final repository = _FakeListingRepository(
      requests: [
        _testRequest(
          'request-pending',
          ListingRequestStatus.pending,
          ownerContactInfo: '0555 111 22 33',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MyRequestsPage(
          repository: repository,
          currentUserId: 'user-1',
          isFirebaseReady: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Beklemede'), findsOneWidget);
    expect(find.text('İlan sahibinin iletişimi: 0555 111 22 33'), findsNothing);
  });

  testWidgets('listings can be searched and filtered', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlanları Gör'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'cam');
    await tester.pump();

    expect(find.text('Cam kavanoz ve şişeler'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsNothing);

    await tester.tap(find.byTooltip('Aramayı temizle'));
    await tester.pump();
    await tester.tap(find.text('Plastik'));
    await tester.pump();

    expect(find.text('Uygun ilan bulunamadı.'), findsOneWidget);
  });
}

Listing _testListing({required String ownerId}) {
  return Listing(
    id: 'listing-1',
    title: 'Karton denemesi',
    category: 'Kağıt',
    location: 'Ortahisar',
    amount: '10 kg',
    description: 'Temiz karton kutular.',
    ownerId: ownerId,
    ownerName: 'Ebranur',
    createdAt: DateTime(2026, 9, 8),
    imageAsset: 'assets/images/cardboard_boxes.svg',
    contactInfo: '0555 111 22 33',
  );
}

ListingRequest _testRequest(
  String id,
  ListingRequestStatus status, {
  String ownerContactInfo = '',
}) {
  return ListingRequest(
    id: id,
    listingId: 'listing-$id',
    listingOwnerId: 'owner-1',
    listingTitle: 'Karton kutular',
    listingAmount: '10 kg',
    listingLocation: 'Ortahisar',
    ownerContactInfo: ownerContactInfo,
    requesterId: 'user-1',
    requesterName: 'Zeynep',
    status: status,
    createdAt: DateTime(2026, 9, 8),
  );
}

class _FakeListingRepository extends ListingRepository {
  _FakeListingRepository({
    this.listings = const [],
    this.requests = const [],
    this.shouldSaveRequest = true,
  });

  final List<Listing> listings;
  final List<ListingRequest> requests;
  final bool shouldSaveRequest;
  int addRequestCount = 0;

  @override
  Stream<List<Listing>> watchListings() => Stream.value(listings);

  @override
  Stream<List<ListingRequest>> watchRequestsByRequester(String userId) {
    return Stream.value(
      requests.where((request) => request.requesterId == userId).toList(),
    );
  }

  @override
  Future<bool> addRequest(ListingRequest request) async {
    addRequestCount += 1;
    return shouldSaveRequest;
  }
}
