import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/services/listing_repository.dart';

typedef InterestChangedCallback = Future<ListingRequest?> Function();

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  static const _categories = ['Tümü', 'Kağıt', 'Plastik', 'Cam', 'Elektronik'];

  final Map<String, ListingRequest> _requestsByListingId = {};
  final Set<String> _savingRequestListingIds = {};
  final _searchController = TextEditingController();
  final _listingRepository = const ListingRepository();

  String _selectedCategory = 'Tümü';
  List<Listing> _listings = sampleListings;

  List<Listing> get _filteredListings {
    final query = _searchController.text.trim().toLowerCase();

    return _listings.where((listing) {
      final matchesCategory =
          _selectedCategory == 'Tümü' || listing.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          listing.title.toLowerCase().contains(query) ||
          listing.category.toLowerCase().contains(query) ||
          listing.location.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _requestIdFor(Listing listing, User? user) {
    final requesterId = user?.uid ?? 'local-user';

    return '$requesterId-${listing.id}'.replaceAll('/', '-');
  }

  ListingRequest _requestForListing(Listing listing) {
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;

    return ListingRequest(
      id: _requestIdFor(listing, user),
      listingId: listing.id,
      listingOwnerId: listing.ownerId,
      listingTitle: listing.title,
      listingAmount: listing.amount,
      listingLocation: listing.location,
      requesterId: user?.uid ?? 'local-user',
      requesterName: user?.displayName ?? user?.email ?? 'Ebranur',
      status: ListingRequestStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  Future<ListingRequest?> _toggleInterest(Listing listing) async {
    if (_savingRequestListingIds.contains(listing.id)) {
      return _requestsByListingId[listing.id];
    }

    final currentRequest = _requestsByListingId[listing.id];
    final isSendingRequest = currentRequest == null;
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;

    if (Firebase.apps.isNotEmpty && user == null) {
      _showRequestMessage('Talep göndermek için giriş yapmalısınız.');
      return currentRequest;
    }

    if (user != null && listing.ownerId == user.uid) {
      _showRequestMessage('Kendi ilanınıza talep gönderemezsiniz.');
      return currentRequest;
    }

    if (Firebase.apps.isNotEmpty &&
        listing.ownerId.startsWith('sample-user-')) {
      _showRequestMessage(
        'Bu örnek ilana talep gönderilemiyor. Önce gerçek bir ilan oluşturun.',
      );
      return currentRequest;
    }

    setState(() => _savingRequestListingIds.add(listing.id));

    final nextRequest = isSendingRequest ? _requestForListing(listing) : null;
    final isSaved = isSendingRequest
        ? await _listingRepository.addRequest(nextRequest!)
        : await _listingRepository.deleteRequest(currentRequest.id);

    if (!mounted) return currentRequest;

    setState(() {
      _savingRequestListingIds.remove(listing.id);
      if (isSaved && nextRequest != null) {
        _requestsByListingId[listing.id] = nextRequest;
      } else if (isSaved) {
        _requestsByListingId.remove(listing.id);
      }
    });

    if (!isSaved) {
      _showRequestMessage(
        isSendingRequest
            ? 'Talep şu anda gönderilemedi.'
            : 'Talep şu anda geri alınamadı.',
      );
      return currentRequest;
    }

    _showRequestMessage(
      isSendingRequest
          ? 'Talebiniz ilan sahibine iletildi.'
          : 'Talebiniz geri alındı.',
    );

    return nextRequest;
  }

  void _showRequestMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
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
        builder: (_) => _ListingDetailPage(
          listing: listing,
          request: _requestsByListingId[listing.id],
          onInterestChanged: () => _toggleInterest(listing),
        ),
      ),
    );
  }

  Widget _buildListingsContent(BuildContext context) {
    final filteredListings = _filteredListings;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'İlanlarda ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? const Icon(Icons.tune)
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: category == _selectedCategory,
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
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: filteredListings.isEmpty
              ? const SliverToBoxAdapter(child: _EmptyListingsMessage())
              : SliverList.separated(
                  itemCount: filteredListings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final listing = filteredListings[index];
                    return _ListingCard(
                      listing: listing,
                      request: _requestsByListingId[listing.id],
                      onTap: () => _openListingDetail(listing),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlanları Gör')),
      body: SafeArea(
        child: StreamBuilder<List<Listing>>(
          stream: _listingRepository.watchListings(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _listings = snapshot.data!;
            }

            final user = Firebase.apps.isNotEmpty
                ? FirebaseAuth.instance.currentUser
                : null;

            if (user == null) {
              _requestsByListingId.clear();
              return _buildListingsContent(context);
            }

            return StreamBuilder<List<ListingRequest>>(
              stream: _listingRepository.watchRequestsByRequester(user.uid),
              builder: (context, requestsSnapshot) {
                if (requestsSnapshot.hasData) {
                  _syncRequests(requestsSnapshot.data!);
                }

                return _buildListingsContent(context);
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyListingsMessage extends StatelessWidget {
  const _EmptyListingsMessage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Uygun ilan bulunamadı.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Arama veya kategori filtresini değiştirmeyi deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.request,
    required this.onTap,
  });

  final Listing listing;
  final ListingRequest? request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusInfo = request == null ? null : _requestStatusInfo(request!);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: _ListingImage(
                  listing: listing,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.category,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.scale_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.amount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (statusInfo != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Talep durumu: ${statusInfo.label}',
                        style: TextStyle(
                          color: statusInfo.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingDetailPage extends StatefulWidget {
  const _ListingDetailPage({
    required this.listing,
    required this.request,
    required this.onInterestChanged,
  });

  final Listing listing;
  final ListingRequest? request;
  final InterestChangedCallback onInterestChanged;

  @override
  State<_ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<_ListingDetailPage> {
  late ListingRequest? _request = widget.request;
  bool _isChangingRequest = false;

  Future<void> _toggleInterest() async {
    if (_isChangingRequest) return;

    setState(() => _isChangingRequest = true);
    final updatedRequest = await widget.onInterestChanged();
    if (!mounted) return;

    setState(() {
      _request = updatedRequest;
      _isChangingRequest = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final listing = widget.listing;

    return Scaffold(
      appBar: AppBar(title: const Text('İlan Detayı')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 180,
                    child: _ListingImage(
                      listing: listing,
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.all(20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${listing.ownerName} tarafından paylaşıldı',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: listing.category,
                      ),
                      _InfoChip(
                        icon: Icons.scale_outlined,
                        label: listing.amount,
                      ),
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: listing.location,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Açıklama',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  if (_request != null) ...[
                    _RequestStatusCard(request: _request!),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _isChangingRequest ? null : _toggleInterest,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: _request != null
                          ? colorScheme.secondary
                          : colorScheme.primary,
                    ),
                    icon: Icon(
                      _isChangingRequest
                          ? Icons.hourglass_empty
                          : _request != null
                          ? Icons.check_circle_outline
                          : Icons.volunteer_activism_outlined,
                    ),
                    label: Text(
                      _isChangingRequest
                          ? 'İşleniyor...'
                          : _request != null
                          ? 'Talebi Geri Al'
                          : 'İlgileniyorum',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestStatusCard extends StatelessWidget {
  const _RequestStatusCard({required this.request});

  final ListingRequest request;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _requestStatusInfo(request);

    return Card(
      elevation: 0,
      color: statusInfo.color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusInfo.icon, color: statusInfo.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Talep durumu: ${statusInfo.label}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestStatusInfo {
  const _RequestStatusInfo(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

_RequestStatusInfo _requestStatusInfo(ListingRequest request) {
  return switch (request.status) {
    ListingRequestStatus.accepted => const _RequestStatusInfo(
      'Kabul edildi',
      Icons.check_circle_outline,
      Color(0xFF2E7D32),
    ),
    ListingRequestStatus.rejected => const _RequestStatusInfo(
      'Reddedildi',
      Icons.cancel_outlined,
      Color(0xFFC62828),
    ),
    ListingRequestStatus.pending => const _RequestStatusInfo(
      'Beklemede',
      Icons.hourglass_top_outlined,
      Color(0xFFF57C00),
    ),
  };
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(icon, size: 18, color: colorScheme.primary),
      label: Text(label),
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
      side: BorderSide.none,
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({
    required this.listing,
    required this.borderRadius,
    required this.padding,
  });

  final Listing listing;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.imageUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: imageUrl == null || imageUrl.isEmpty
          ? Container(
              color: _listingColor(listing).withValues(alpha: 0.14),
              padding: padding,
              child: SvgPicture.asset(
                listing.imageAsset,
                semanticsLabel: listing.title,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: _listingColor(listing).withValues(alpha: 0.14),
                  padding: padding,
                  child: SvgPicture.asset(
                    listing.imageAsset,
                    semanticsLabel: listing.title,
                  ),
                );
              },
            ),
    );
  }
}

Color _listingColor(Listing listing) {
  switch (listing.category) {
    case 'Kağıt':
      return const Color(0xFF8D6E63);
    case 'Cam':
      return const Color(0xFF00897B);
    case 'Elektronik':
      return const Color(0xFF5E35B1);
    default:
      return const Color(0xFF2E7D32);
  }
}
