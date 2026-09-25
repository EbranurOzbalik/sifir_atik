import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/data/waste_categories.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/notification_service.dart';
import 'package:sifir_atik/theme/app_theme.dart';
import 'package:sifir_atik/widgets/listing_preview_card.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

import 'create_listing_page.dart';
import 'listings_page.dart';
import 'moderation_page.dart';
import 'my_listings_page.dart';
import 'my_requests_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.repository = const ListingRepository()});

  final ListingRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  StreamSubscription<void>? _notificationTapSubscription;

  User? get _user =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

  String? get _currentUserName => _user?.displayName ?? _user?.email;

  @override
  void initState() {
    super.initState();
    _notificationTapSubscription = NotificationService.instance.notificationTaps
        .listen((_) => _openNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = _user?.uid;
      if (userId != null) {
        NotificationService.instance.initialize(userId);
      }
    });
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  void _openNotifications() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationsPage()));
  }

  void _selectPage(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CreateListingPage()),
      );
      return;
    }

    setState(() => _selectedIndex = index);
  }

  void _openMyListings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MyListingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeFeed(
        repository: widget.repository,
        currentUserId: _user?.uid,
        currentUserName: _currentUserName,
        onExplore: () => _selectPage(1),
        onProfile: () => _selectPage(4),
        onNotifications: _openNotifications,
        onMyListings: _openMyListings,
      ),
      ListingsPage(repository: widget.repository, embedded: true),
      const SizedBox.shrink(),
      MyRequestsPage(repository: widget.repository, embedded: true),
      ProfilePage(repository: widget.repository, embedded: true),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: _AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectPage,
      ),
    );
  }
}

class _HomeFeed extends StatelessWidget {
  const _HomeFeed({
    required this.repository,
    required this.currentUserId,
    required this.currentUserName,
    required this.onExplore,
    required this.onProfile,
    required this.onNotifications,
    required this.onMyListings,
  });

  final ListingRepository repository;
  final String? currentUserId;
  final String? currentUserName;
  final VoidCallback onExplore;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final VoidCallback onMyListings;

  void _openDetail(BuildContext context, Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingDetailPage(
          listing: listing,
          repository: repository,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          isFirebaseReady: Firebase.apps.isNotEmpty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = responsiveHorizontalPadding(context);

    return SafeArea(
      child: StreamBuilder<List<Listing>>(
        stream: repository.watchListings(),
        initialData: sampleListings,
        builder: (context, snapshot) {
          final listings = snapshot.data ?? sampleListings;
          final visibleListings = listings.take(6).toList();

          return CustomScrollView(
            key: const PageStorageKey('home-feed-scroll'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveContent(
                    maxWidth: 980,
                    child: _HomeHero(
                      currentUserName: currentUserName,
                      currentUserId: currentUserId,
                      onProfile: onProfile,
                      onNotifications: onNotifications,
                      onExplore: onExplore,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveContent(
                    maxWidth: 980,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: listingFilterCategories
                            .take(7)
                            .map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _CategoryPill(
                                  category: category,
                                  onTap: onExplore,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  22,
                  horizontalPadding,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveContent(
                    maxWidth: 980,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Son eklenen ilanlar',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: onExplore,
                          child: const Text('Tümünü gör'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 270,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final listing = visibleListings[index];
                    return ListingPreviewCard(
                      listing: listing,
                      onTap: () => _openDetail(context, listing),
                    );
                  }, childCount: visibleListings.length),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  22,
                  horizontalPadding,
                  28,
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveContent(
                    maxWidth: 980,
                    child: Column(
                      children: [
                        _MyListingsShortcut(onTap: onMyListings),
                        if (currentUserId != null)
                          FutureBuilder<bool>(
                            future: repository.isModerator(currentUserId!),
                            builder: (context, snapshot) {
                              if (snapshot.data != true) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _ModeratorShortcut(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ModerationPage(
                                          repository: repository,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.currentUserName,
    required this.currentUserId,
    required this.onProfile,
    required this.onNotifications,
    required this.onExplore,
  });

  final String? currentUserName;
  final String? currentUserId;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final firstName = currentUserName?.trim().split(RegExp(r'\s+')).first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sıfır Atık',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    firstName == null || firstName.isEmpty
                        ? 'Paylaş, değerlendir, yeniden kullan.'
                        : 'Merhaba $firstName, bugün ne paylaşmak istersin?',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            NotificationBell(userId: currentUserId, onPressed: onNotifications),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Profilim',
              onPressed: onProfile,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.forest,
                fixedSize: const Size.square(44),
              ),
              icon: const Icon(Icons.account_circle_outlined, size: 27),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Material(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onExplore,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.muted, size: 21),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'İlanlarda ara',
                      style: TextStyle(color: AppColors.muted, fontSize: 16),
                    ),
                  ),
                  Icon(Icons.tune_rounded, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category, required this.onTap});

  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlighted = category == 'Tümü';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.forest : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _categoryIcon(category),
                size: 17,
                color: highlighted ? Colors.white : AppColors.forest,
              ),
              const SizedBox(width: 7),
              Text(
                category,
                style: TextStyle(
                  color: highlighted ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyListingsShortcut extends StatelessWidget {
  const _MyListingsShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeShortcut(
      icon: Icons.inventory_2_outlined,
      title: 'İlanlarım',
      description: 'Paylaştığım ilanları ve gelen talepleri yönet.',
      onTap: onTap,
    );
  }
}

class _ModeratorShortcut extends StatelessWidget {
  const _ModeratorShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeShortcut(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Bildirilen İlanlar',
      description: 'Kullanıcı bildirimlerini moderatör olarak incele.',
      onTap: onTap,
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
          ),
        ),
      ),
    );
  }
}

class _AppBottomNavigation extends StatelessWidget {
  const _AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Ana Sayfa'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Keşfet'),
    (Icons.add_rounded, Icons.add_rounded, 'İlan Ver'),
    (Icons.handshake_outlined, Icons.handshake_rounded, 'Talepler'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              return Expanded(
                child: _BottomNavItem(
                  icon: item.$1,
                  selectedIcon: item.$2,
                  label: item.$3,
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          selected ? selectedIcon : icon,
          color: selected ? AppColors.forest : AppColors.muted,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: selected ? AppColors.forest : AppColors.muted,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Tümü' => Icons.grid_view_rounded,
    'Kağıt' => Icons.inventory_2_outlined,
    'Plastik' => Icons.local_drink_outlined,
    'Cam' => Icons.wine_bar_outlined,
    'Metal' => Icons.hardware_outlined,
    'Elektronik' => Icons.devices_other_outlined,
    'Tekstil' => Icons.checkroom_outlined,
    _ => Icons.recycling_rounded,
  };
}
