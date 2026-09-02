import 'package:flutter/material.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  static const _categories = ['Tümü', 'Kağıt', 'Plastik', 'Cam', 'Elektronik'];
  static const _listings = [
    _Listing(
      title: 'Temiz karton kutular',
      category: 'Kağıt',
      location: 'Kadıköy, İstanbul',
      amount: '10 kg',
      description:
          'Taşınmadan kalan temiz karton kutular. Katlanmış şekilde teslim edilebilir.',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF8D6E63),
    ),
    _Listing(
      title: 'Cam kavanoz ve şişeler',
      category: 'Cam',
      location: 'Üsküdar, İstanbul',
      amount: '18 adet',
      description:
          'Etiketleri sökülmüş, yıkanmış kavanoz ve cam şişeler. Geri kullanım için uygundur.',
      icon: Icons.local_drink_outlined,
      color: Color(0xFF00897B),
    ),
    _Listing(
      title: 'Kullanılabilir elektronik parçalar',
      category: 'Elektronik',
      location: 'Ataşehir, İstanbul',
      amount: '1 kutu',
      description:
          'Eski cihazlardan ayrılmış kablo, adaptör ve küçük elektronik parçalar.',
      icon: Icons.memory_outlined,
      color: Color(0xFF5E35B1),
    ),
  ];

  final Set<String> _interestedListingTitles = {};
  final _searchController = TextEditingController();

  String _selectedCategory = 'Tümü';

  List<_Listing> get _filteredListings {
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

  void _toggleInterest(_Listing listing) {
    setState(() {
      if (_interestedListingTitles.contains(listing.title)) {
        _interestedListingTitles.remove(listing.title);
      } else {
        _interestedListingTitles.add(listing.title);
      }
    });
  }

  void _openListingDetail(_Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ListingDetailPage(
          listing: listing,
          isInterested: _interestedListingTitles.contains(listing.title),
          onInterestChanged: () => _toggleInterest(listing),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredListings = _filteredListings;

    return Scaffold(
      appBar: AppBar(title: const Text('İlanları Gör')),
      body: SafeArea(
        child: CustomScrollView(
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
                          isInterested: _interestedListingTitles.contains(
                            listing.title,
                          ),
                          onTap: () => _openListingDetail(listing),
                        );
                      },
                    ),
            ),
          ],
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
    required this.isInterested,
    required this.onTap,
  });

  final _Listing listing;
  final bool isInterested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: listing.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(listing.icon, size: 36, color: listing.color),
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
                        Text(
                          listing.amount,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                    if (isInterested) ...[
                      const SizedBox(height: 8),
                      Text(
                        'İlginiz iletildi',
                        style: TextStyle(
                          color: colorScheme.primary,
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
    required this.isInterested,
    required this.onInterestChanged,
  });

  final _Listing listing;
  final bool isInterested;
  final VoidCallback onInterestChanged;

  @override
  State<_ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<_ListingDetailPage> {
  late bool _isInterested = widget.isInterested;

  void _toggleInterest() {
    widget.onInterestChanged();
    setState(() => _isInterested = !_isInterested);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _isInterested
                ? 'Talebiniz ilan sahibine iletildi.'
                : 'Talebiniz geri alındı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: listing.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(listing.icon, size: 72, color: listing.color),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  FilledButton.icon(
                    onPressed: _toggleInterest,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: _isInterested
                          ? colorScheme.secondary
                          : colorScheme.primary,
                    ),
                    icon: Icon(
                      _isInterested
                          ? Icons.check_circle_outline
                          : Icons.volunteer_activism_outlined,
                    ),
                    label: Text(
                      _isInterested ? 'Talep İletildi' : 'İlgileniyorum',
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

class _Listing {
  const _Listing({
    required this.title,
    required this.category,
    required this.location,
    required this.amount,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String category;
  final String location;
  final String amount;
  final String description;
  final IconData icon;
  final Color color;
}
