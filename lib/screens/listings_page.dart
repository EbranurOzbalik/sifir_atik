import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/data/waste_categories.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_report.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/models/user_profile.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/location_service.dart';
import 'package:sifir_atik/theme/app_theme.dart';
import 'package:sifir_atik/widgets/listing_preview_card.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({
    super.key,
    this.repository = const ListingRepository(),
    this.currentUserId,
    this.currentUserName,
    this.isFirebaseReady,
    this.embedded = false,
    this.locationClient = const DeviceLocationService(),
  });

  final ListingRepository repository;
  final String? currentUserId;
  final String? currentUserName;
  final bool? isFirebaseReady;
  final bool embedded;
  final LocationClient locationClient;

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  static const _nearbyRadiusKm = 25.0;

  final Map<String, ListingRequest> _requestsByListingId = {};
  final _searchController = TextEditingController();

  String _selectedCategory = 'Tümü';
  AccountType? _selectedOwnerType;
  List<Listing> _listings = sampleListings;
  AppLocation? _currentLocation;
  bool _nearbyOnly = false;
  bool _isLocating = false;

  bool get _hasFirebase => widget.isFirebaseReady ?? Firebase.apps.isNotEmpty;

  User? get _firebaseUser => _hasFirebase && Firebase.apps.isNotEmpty
      ? FirebaseAuth.instance.currentUser
      : null;

  String? get _currentUserId => widget.currentUserId ?? _firebaseUser?.uid;

  String? get _currentUserName =>
      widget.currentUserName ??
      _firebaseUser?.displayName ??
      _firebaseUser?.email;

  List<Listing> get _filteredListings {
    final query = _searchController.text.trim().toLowerCase();

    final matchingListings = _listings.where((listing) {
      final matchesCategory =
          _selectedCategory == 'Tümü' || listing.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          listing.title.toLowerCase().contains(query) ||
          listing.category.toLowerCase().contains(query) ||
          listing.location.toLowerCase().contains(query);
      final matchesOwnerType =
          _selectedOwnerType == null ||
          listing.ownerAccountType == _selectedOwnerType;

      return matchesCategory && matchesQuery && matchesOwnerType;
    }).toList();

    if (!_nearbyOnly || _currentLocation == null) return matchingListings;

    return matchingListings.where((listing) {
      final distance = _distanceFor(listing);
      return distance != null && distance <= _nearbyRadiusKm;
    }).toList()..sort(
      (first, second) => _distanceFor(first)!.compareTo(_distanceFor(second)!),
    );
  }

  double? _distanceFor(Listing listing) {
    final currentLocation = _currentLocation;
    if (currentLocation == null || !listing.hasCoordinates) return null;

    return distanceInKilometers(
      currentLocation,
      AppLocation(latitude: listing.latitude!, longitude: listing.longitude!),
    );
  }

  Future<void> _toggleNearby() async {
    if (_nearbyOnly) {
      setState(() => _nearbyOnly = false);
      return;
    }
    if (_isLocating) return;

    setState(() => _isLocating = true);
    try {
      final location = await widget.locationClient.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _nearbyOnly = true;
      });
    } on LocationServiceException catch (error) {
      _showLocationMessage(error.message);
    } catch (_) {
      _showLocationMessage('Konum alınamadı. Biraz sonra tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncRequests(List<ListingRequest> requests) {
    _requestsByListingId
      ..clear()
      ..addEntries(
        requests.map((request) => MapEntry(request.listingId, request)),
      );
  }

  void _openListingDetail(Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingDetailPage(
          listing: listing,
          request: _requestsByListingId[listing.id],
          repository: widget.repository,
          currentUserId: _currentUserId,
          currentUserName: _currentUserName,
          isFirebaseReady: _hasFirebase,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final filteredListings = _filteredListings;
    final horizontalPadding = responsiveHorizontalPadding(context);

    return CustomScrollView(
      key: const PageStorageKey('listings-scroll'),
      slivers: [
        if (widget.embedded)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              22,
              horizontalPadding,
              14,
            ),
            sliver: SliverToBoxAdapter(
              child: ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keşfet',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paylaşılan atık ilanlarına göz at.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            2,
            horizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: ResponsiveContent(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  selected: _nearbyOnly,
                  avatar: _isLocating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.near_me_outlined, size: 17),
                  label: const Text('Yakınımdakiler'),
                  onSelected: _isLocating ? null : (_) => _toggleNearby(),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            widget.embedded ? 4 : 16,
            horizontalPadding,
            12,
          ),
          sliver: SliverToBoxAdapter(
            child: ResponsiveContent(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'İlanlarda ara',
                  fillColor: AppColors.secondarySurface,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? const Icon(Icons.tune_rounded)
                      : IconButton(
                          tooltip: 'Aramayı temizle',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: ResponsiveContent(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      selected: _selectedOwnerType == null,
                      label: const Text('Tüm hesaplar'),
                      onSelected: (_) {
                        setState(() => _selectedOwnerType = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      selected: _selectedOwnerType == AccountType.individual,
                      avatar: const Icon(Icons.person_outline, size: 17),
                      label: const Text('Bireysel'),
                      onSelected: (_) {
                        setState(
                          () => _selectedOwnerType = AccountType.individual,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      selected: _selectedOwnerType == AccountType.organization,
                      avatar: const Icon(Icons.apartment_outlined, size: 17),
                      label: const Text('Kurumsal'),
                      onSelected: (_) {
                        setState(
                          () => _selectedOwnerType = AccountType.organization,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverToBoxAdapter(
            child: ResponsiveContent(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: listingFilterCategories
                      .map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: category == _selectedCategory,
                            showCheckmark: category == _selectedCategory,
                            onSelected: (_) {
                              setState(() => _selectedCategory = category);
                            },
                            label: Text(category),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        if (_nearbyOnly)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: ResponsiveContent(
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      size: 17,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '25 km içindeki ilanlar yakından uzağa sıralanıyor.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (filteredListings.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyListingsMessage(isNearbyFilter: _nearbyOnly),
          )
        else
          SliverPadding(
            padding: responsivePagePadding(context, top: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 270,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final listing = filteredListings[index];
                return ListingPreviewCard(
                  listing: listing,
                  request: _requestsByListingId[listing.id],
                  distanceKm: _nearbyOnly ? _distanceFor(listing) : null,
                  onTap: () => _openListingDetail(listing),
                );
              }, childCount: filteredListings.length),
            ),
          ),
      ],
    );
  }

  Widget _buildStreamContent() {
    return StreamBuilder<List<Listing>>(
      stream: widget.repository.watchListings(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _listings = snapshot.data!;
        }

        final userId = _currentUserId;
        if (userId == null) {
          _requestsByListingId.clear();
          return _buildContent(context);
        }

        return StreamBuilder<List<ListingRequest>>(
          stream: widget.repository.watchRequestsByRequester(userId),
          builder: (context, requestsSnapshot) {
            if (requestsSnapshot.hasData) {
              _syncRequests(requestsSnapshot.data!);
            }
            return _buildContent(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(child: _buildStreamContent());
    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Keşfet')),
      body: content,
    );
  }
}

class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({
    super.key,
    required this.listing,
    required this.repository,
    this.request,
    this.currentUserId,
    this.currentUserName,
    this.isFirebaseReady,
  });

  final Listing listing;
  final ListingRequest? request;
  final ListingRepository repository;
  final String? currentUserId;
  final String? currentUserName;
  final bool? isFirebaseReady;

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  static const _reportReasons = [
    'Yanlış kategori',
    'Uygunsuz açıklama',
    'Şüpheli iletişim bilgisi',
    'İlan artık geçerli değil',
  ];

  late ListingRequest? _request = widget.request;
  bool _isChangingRequest = false;
  bool _isReporting = false;
  bool _isSaved = false;

  bool get _hasFirebase => widget.isFirebaseReady ?? Firebase.apps.isNotEmpty;

  User? get _firebaseUser => _hasFirebase && Firebase.apps.isNotEmpty
      ? FirebaseAuth.instance.currentUser
      : null;

  String? get _currentUserId => widget.currentUserId ?? _firebaseUser?.uid;

  String? get _currentUserName =>
      widget.currentUserName ??
      _firebaseUser?.displayName ??
      _firebaseUser?.email;

  ListingRequest _createRequest() {
    final listing = widget.listing;
    final requesterId = _currentUserId ?? 'local-user';

    return ListingRequest(
      id: '$requesterId-${listing.id}'.replaceAll('/', '-'),
      listingId: listing.id,
      listingOwnerId: listing.ownerId,
      listingTitle: listing.title,
      listingAmount: listing.amount,
      listingLocation: listing.location,
      ownerContactInfo: listing.contactInfo,
      requesterId: requesterId,
      requesterName: _currentUserName ?? 'Kullanıcı',
      status: ListingRequestStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _toggleInterest() async {
    if (_isChangingRequest) return;

    final userId = _currentUserId;
    if (_hasFirebase && userId == null) {
      _showMessage('Talep göndermek için giriş yapmalısınız.');
      return;
    }
    if (userId != null && widget.listing.ownerId == userId) {
      _showMessage('Kendi ilanınıza talep gönderemezsiniz.');
      return;
    }
    if (_hasFirebase && widget.listing.ownerId.startsWith('sample-user-')) {
      _showMessage(
        'Bu örnek ilana talep gönderilemiyor. Önce gerçek bir ilan oluşturun.',
      );
      return;
    }

    setState(() => _isChangingRequest = true);

    final currentRequest = _request;
    final nextRequest = currentRequest == null ? _createRequest() : null;
    final isSaved = currentRequest == null
        ? await widget.repository.addRequest(nextRequest!)
        : await widget.repository.deleteRequest(currentRequest.id);

    if (!mounted) return;

    setState(() {
      _isChangingRequest = false;
      if (isSaved) _request = nextRequest;
    });

    if (!isSaved) {
      _showMessage(
        currentRequest == null
            ? 'Talep şu anda gönderilemedi.'
            : 'Talep şu anda geri alınamadı.',
      );
      return;
    }

    _showMessage(
      nextRequest == null
          ? 'Talebiniz geri alındı.'
          : 'Talebiniz ilan sahibine iletildi.',
    );
  }

  Future<void> _reportListing() async {
    if (_isReporting) return;

    final userId = _currentUserId;
    if (_hasFirebase && userId == null) {
      _showMessage('İlan bildirmek için giriş yapmalısınız.');
      return;
    }
    if (userId != null && widget.listing.ownerId == userId) {
      _showMessage('Kendi ilanınızı bildiremezsiniz.');
      return;
    }

    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İlanı neden bildiriyorsunuz?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ..._reportReasons.map(
                  (reason) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(reason),
                    onTap: () => Navigator.of(context).pop(reason),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (reason == null || !mounted) return;

    setState(() => _isReporting = true);
    final listing = widget.listing;
    final report = ListingReport(
      id: '${userId ?? 'local-user'}-${listing.id}'.replaceAll('/', '-'),
      listingId: listing.id,
      listingOwnerId: listing.ownerId,
      listingTitle: listing.title,
      listingAmount: listing.amount,
      listingLocation: listing.location,
      listingCategory: listing.category,
      listingDescription: listing.description,
      reporterId: userId ?? 'local-user',
      reporterName: _currentUserName ?? 'Kullanıcı',
      reason: reason,
      status: ListingReportStatus.open,
      createdAt: DateTime.now(),
    );
    final isSaved = await widget.repository.addReport(report);

    if (!mounted) return;
    setState(() => _isReporting = false);
    _showMessage(
      isSaved
          ? 'İlan bildirildi. Moderatör inceleyebilir.'
          : 'İlan şu anda bildirilemedi.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Kaydedilenlerden çıkar' : 'İlanı kaydet',
            onPressed: () => setState(() => _isSaved = !_isSaved),
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePagePadding(context, top: 8, bottom: 124),
          child: ResponsiveContent(
            maxWidth: kFormContentMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1.18,
                  child: ListingImageView(
                    listing: listing,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(34),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: listingCategoryColor(
                          listing.category,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        listing.category,
                        style: TextStyle(
                          color: listingCategoryColor(listing.category),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${listing.amount} • ${listing.location}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _OwnerCard(listing: listing),
                const SizedBox(height: 24),
                Text(
                  'Açıklama',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.eco_outlined, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bu ilan, kullanılabilir bir malzemenin yeniden değerlendirilmesine yardımcı olur.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_request != null) ...[
                  const SizedBox(height: 18),
                  _RequestStatusCard(request: _request!),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isReporting ? null : _reportListing,
                  icon: Icon(
                    _isReporting ? Icons.hourglass_empty : Icons.flag_outlined,
                  ),
                  label: Text(
                    _isReporting ? 'Bildiriliyor...' : 'İlanı Bildir',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: _isSaved ? 'Kaydedilenlerden çıkar' : 'İlanı kaydet',
                onPressed: () => setState(() => _isSaved = !_isSaved),
                icon: Icon(
                  _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isChangingRequest ? null : _toggleInterest,
                  icon: Icon(
                    _isChangingRequest
                        ? Icons.hourglass_empty_rounded
                        : _request == null
                        ? Icons.handshake_outlined
                        : Icons.close_rounded,
                  ),
                  label: Text(
                    _isChangingRequest
                        ? 'İşleniyor...'
                        : _request == null
                        ? 'Talep Et'
                        : 'Talebi Geri Al',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              listing.ownerAccountType == AccountType.organization
                  ? Icons.apartment_rounded
                  : Icons.person_outline_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      listing.ownerAccountType == AccountType.organization
                          ? 'Kurumsal ilan sahibi'
                          : 'Bireysel ilan sahibi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (listing.isOwnerVerified)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Doğrulanmış',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _RequestStatusCard extends StatelessWidget {
  const _RequestStatusCard({required this.request});

  final ListingRequest request;

  @override
  Widget build(BuildContext context) {
    final color = requestStatusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_requestStatusIcon(request.status), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Talep durumu: ${requestStatusLabel(request.status)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyListingsMessage extends StatelessWidget {
  const _EmptyListingsMessage({this.isNearbyFilter = false});

  final bool isNearbyFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              isNearbyFilter
                  ? 'Yakınınızda ilan bulunamadı.'
                  : 'Uygun ilan bulunamadı.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              isNearbyFilter
                  ? '25 km içindeki ilanlarda konum bilgisi bulunmuyor olabilir.'
                  : 'Arama veya kategori filtresini değiştirmeyi deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _requestStatusIcon(ListingRequestStatus status) {
  return switch (status) {
    ListingRequestStatus.accepted => Icons.check_circle_outline_rounded,
    ListingRequestStatus.rejected => Icons.cancel_outlined,
    ListingRequestStatus.pending => Icons.hourglass_top_rounded,
  };
}
