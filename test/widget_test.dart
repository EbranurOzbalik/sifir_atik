import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifir_atik/data/waste_categories.dart';
import 'package:sifir_atik/main.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_report.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/screens/create_listing_page.dart';
import 'package:sifir_atik/screens/home_page.dart';
import 'package:sifir_atik/screens/listings_page.dart';
import 'package:sifir_atik/screens/moderation_page.dart';
import 'package:sifir_atik/screens/my_requests_page.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/location_service.dart';
import 'package:sifir_atik/services/moderation_ai_service.dart';

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

    expect(find.text('Hesap türü'), findsOneWidget);
    expect(find.text('Bireysel'), findsOneWidget);
    expect(find.text('Şirket / Kurum'), findsOneWidget);
    expect(find.text('Ad soyad'), findsOneWidget);
    expect(find.text('Şifre tekrar'), findsOneWidget);
    expect(find.text('Hesap Oluştur'), findsOneWidget);
    expect(find.text('Zaten hesabın var mı?'), findsOneWidget);
  });

  testWidgets('organization registration changes the name field', (
    tester,
  ) async {
    await tester.pumpWidget(const SifirAtikApp());

    await tester.ensureVisible(find.text('Kayıt Ol'));
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pump();
    await tester.tap(find.text('Şirket / Kurum'));
    await tester.pump();

    expect(find.text('Şirket / kurum adı'), findsOneWidget);
    expect(find.text('Kurum türü'), findsOneWidget);
    expect(find.text('Yetkili kişi'), findsOneWidget);
    expect(find.text('Şehir'), findsOneWidget);
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

    await tester.tap(find.text('İlan Ver'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni ilan oluştur'), findsOneWidget);
  });

  testWidgets('create listing requires amount and submits draft', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlan Ver'));
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
    await tester.enterText(find.byType(TextFormField).at(3), 'Trabzon');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(4), 'Ortahisar');
    await tester.enterText(find.byType(TextFormField).at(5), '0555 111 22 33');
    await tester.ensureVisible(find.text('İlanı Oluştur'));
    await tester.tap(find.text('İlanı Oluştur'));
    await tester.pump();

    expect(find.text('İlan taslak olarak kaldı.'), findsOneWidget);
  });

  testWidgets('create listing requires a valid phone number', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('İlan Ver'));
    await tester.pumpAndSettle();

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
    await tester.enterText(find.byType(TextFormField).at(3), 'Trabzon');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(4), 'Ortahisar');
    await tester.enterText(find.byType(TextFormField).at(5), '123');
    await tester.ensureVisible(find.text('İlanı Oluştur'));
    await tester.tap(find.text('İlanı Oluştur'));
    await tester.pump();

    expect(find.text('Geçerli bir telefon numarası girin.'), findsOneWidget);
    expect(find.text('İlan taslak olarak kaldı.'), findsNothing);
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

    await tester.tap(find.text('Keşfet'));
    await tester.pump();

    expect(find.text('İlanlarda ara'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsOneWidget);
  });

  testWidgets('home shows main navigation and opens profile shortcut', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.byTooltip('Profilim'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Keşfet'), findsOneWidget);
    expect(find.text('İlan Ver'), findsOneWidget);
    expect(find.text('Talepler'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.byTooltip('Profilim'));
    await tester.pumpAndSettle();

    expect(find.text('Bildirimler'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pump();
    expect(find.text('Çıkış Yap'), findsOneWidget);
    expect(find.text('Hesabımı Sil'), findsOneWidget);
  });

  testWidgets('AI moderator reviews a reported listing without acting', (
    tester,
  ) async {
    final report = ListingReport(
      id: 'report-1',
      listingId: 'listing-1',
      listingOwnerId: 'owner-1',
      listingTitle: 'Şüpheli elektronik ilanı',
      listingAmount: '2 adet',
      listingLocation: 'Ortahisar',
      listingCategory: 'Elektronik',
      listingDescription: 'Detay için başka numaraya ödeme gönderin.',
      reporterId: 'user-1',
      reporterName: 'Zeynep',
      reason: 'Şüpheli iletişim bilgisi',
      status: ListingReportStatus.open,
      createdAt: DateTime(2026, 9, 17),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ModerationPage(
          repository: _FakeListingRepository(reports: [report]),
          aiClient: _FakeModerationAiClient(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Akıllı ön inceleme'), findsOneWidget);
    await tester.tap(find.text('Ön İnceleme Yap'));
    await tester.pumpAndSettle();

    expect(find.text('Yüksek risk'), findsOneWidget);
    expect(find.text('Kaldırılması değerlendirilmeli'), findsOneWidget);
    expect(find.textContaining('kendiliğinden uygulanmaz'), findsOneWidget);
  });

  test('waste categories include detailed listing options', () {
    expect(wasteCategories, containsAll(['Tekstil', 'Pil', 'Atık Yağ']));
    expect(listingFilterCategories.first, 'Tümü');
  });

  test('local moderation fallback flags suspicious payment content', () async {
    final report = ListingReport(
      id: 'report-2',
      listingId: 'listing-2',
      listingOwnerId: 'owner-2',
      listingTitle: 'Elektronik atık',
      listingAmount: '1 adet',
      listingLocation: 'Ortahisar',
      listingCategory: 'Elektronik',
      listingDescription: 'Kapora için IBAN üzerinden ödeme gönderin.',
      reporterId: 'user-2',
      reporterName: 'Kullanıcı',
      reason: 'Şüpheli iletişim bilgisi',
      status: ListingReportStatus.open,
      createdAt: DateTime(2026, 9, 17),
    );

    final assessment = await ModerationAiService().analyze(report);

    expect(assessment.isLocalFallback, isTrue);
    expect(assessment.risk, ModerationRisk.high);
    expect(assessment.recommendation, ModerationRecommendation.considerRemoval);
  });

  testWidgets('home navigation opens my listings and requests screens', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.scrollUntilVisible(
      find.text('İlanlarım'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pump();
    await tester.tap(find.text('İlanlarım'));
    await tester.pumpAndSettle();
    expect(find.text('Giriş bulunamadı'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Talepler'));
    await tester.pump();
    expect(
      find.text('Taleplerinizi görmek için giriş yapmalısınız.'),
      findsOneWidget,
    );
  });

  testWidgets('listing detail does not mark unsaved interest as sent', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ListingsPage()));

    await tester.tap(find.text('Temiz karton kutular'));
    await tester.pumpAndSettle();

    expect(find.text('İlan Detayı'), findsOneWidget);
    expect(find.textContaining('10 kg'), findsWidgets);
    expect(find.text('Açıklama'), findsOneWidget);

    await tester.tap(find.text('Talep Et'));
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
    await tester.tap(find.text('Talep Et'));
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
    await tester.tap(find.text('Talep Et'));
    await tester.pump();

    expect(repository.addRequestCount, 1);
    expect(find.text('Talep şu anda gönderilemedi.'), findsOneWidget);
    expect(find.text('Talep İletildi'), findsNothing);
    expect(find.text('Talep durumu: Beklemede'), findsNothing);
  });

  testWidgets('listing detail can report another user listing', (tester) async {
    final listing = _testListing(ownerId: 'owner-1');
    final repository = _FakeListingRepository(listings: [listing]);

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
    await tester.ensureVisible(find.text('İlanı Bildir'));
    await tester.tap(find.text('İlanı Bildir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yanlış kategori'));
    await tester.pump();

    expect(repository.addReportCount, 1);
    expect(repository.lastReport?.listingId, listing.id);
    expect(repository.lastReport?.reason, 'Yanlış kategori');
    expect(
      find.text('İlan bildirildi. Moderatör inceleyebilir.'),
      findsOneWidget,
    );
  });

  testWidgets('user cannot report their own listing', (tester) async {
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
    await tester.ensureVisible(find.text('İlanı Bildir'));
    await tester.tap(find.text('İlanı Bildir'));
    await tester.pump();

    expect(repository.addReportCount, 0);
    expect(find.text('Kendi ilanınızı bildiremezsiniz.'), findsOneWidget);
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

    expect(find.text('Beklemede'), findsWidgets);
    expect(find.text('Kabul edildi'), findsOneWidget);
    expect(find.text('İlan sahibinin telefonu'), findsOneWidget);
    expect(find.text('0555 111 22 33'), findsOneWidget);
    expect(find.text('Talep gönderildi: 8 Eylül'), findsWidgets);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text("WhatsApp'tan yaz"), findsOneWidget);

    await tester.ensureVisible(find.text('Reddedildi', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(find.text('Reddedildi'), findsOneWidget);
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

    expect(find.text('Beklemede'), findsWidgets);
    expect(find.text('İlan sahibinin telefonu'), findsNothing);
    expect(find.text('0555 111 22 33'), findsNothing);
    expect(find.text('Ara'), findsNothing);
    expect(find.text("WhatsApp'tan yaz"), findsNothing);
  });

  testWidgets('listings can be searched and filtered', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('Keşfet'));
    await tester.pump();

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

  testWidgets('listings can be filtered by account type', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ListingsPage()));
    await tester.pump();

    expect(find.text('Doğrulanmış kurum'), findsOneWidget);

    await tester.tap(find.text('Kurumsal'));
    await tester.pump();

    expect(find.text('Cam kavanoz ve şişeler'), findsOneWidget);
    expect(find.text('Temiz karton kutular'), findsNothing);
  });

  testWidgets('nearby listings are filtered and sorted by distance', (
    tester,
  ) async {
    final nearbyListing = _testListing(
      ownerId: 'owner-near',
    ).copyWith(title: 'Yakındaki kartonlar', latitude: 41.009, longitude: 29);
    final farListing = _testListing(
      ownerId: 'owner-far',
    ).copyWith(title: 'Uzaktaki kartonlar', latitude: 42, longitude: 30);

    await tester.pumpWidget(
      MaterialApp(
        home: ListingsPage(
          repository: _FakeListingRepository(
            listings: [farListing, nearbyListing],
          ),
          locationClient: const _FakeLocationClient(
            AppLocation(latitude: 41, longitude: 29),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Yakınımdakiler'));
    await tester.pumpAndSettle();

    expect(find.text('Yakındaki kartonlar'), findsOneWidget);
    expect(find.text('Uzaktaki kartonlar'), findsNothing);
    expect(find.text('1,0 km'), findsOneWidget);
    expect(
      find.text('25 km içindeki ilanlar yakından uzağa sıralanıyor.'),
      findsOneWidget,
    );
  });

  test('distance calculation returns kilometers between two points', () {
    const first = AppLocation(latitude: 41, longitude: 29);
    const second = AppLocation(latitude: 41.009, longitude: 29);

    final distance = distanceInKilometers(first, second);

    expect(distance, closeTo(1, 0.02));
    expect(formatDistance(distance), '1,0 km');
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
    this.reports = const [],
    this.shouldSaveRequest = true,
  });

  final List<Listing> listings;
  final List<ListingRequest> requests;
  final List<ListingReport> reports;
  final bool shouldSaveRequest;
  int addRequestCount = 0;
  int addReportCount = 0;
  ListingReport? lastReport;

  @override
  Stream<List<Listing>> watchListings() => Stream.value(listings);

  @override
  Stream<List<ListingRequest>> watchRequestsByRequester(String userId) {
    return Stream.value(
      requests.where((request) => request.requesterId == userId).toList(),
    );
  }

  @override
  Stream<List<ListingReport>> watchOpenReports() => Stream.value(reports);

  @override
  Future<bool> addRequest(ListingRequest request) async {
    addRequestCount += 1;
    return shouldSaveRequest;
  }

  @override
  Future<bool> addReport(ListingReport report) async {
    addReportCount += 1;
    lastReport = report;
    return true;
  }
}

class _FakeModerationAiClient implements ModerationAiClient {
  @override
  Future<ModerationAssessment> analyze(ListingReport report) async {
    return const ModerationAssessment(
      risk: ModerationRisk.high,
      recommendation: ModerationRecommendation.considerRemoval,
      summary: 'İlanda şüpheli ödeme yönlendirmesi bulunuyor.',
      reason: 'Kullanıcı uygulama dışındaki bir numaraya yönlendiriliyor.',
    );
  }
}

class _FakeLocationClient implements LocationClient {
  const _FakeLocationClient(this.location);

  final AppLocation location;

  @override
  Future<AppLocation> getCurrentLocation() async => location;
}
