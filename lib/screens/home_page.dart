import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/theme/app_theme.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

import 'create_listing_page.dart';
import 'listings_page.dart';
import 'moderation_page.dart';
import 'my_listings_page.dart';
import 'my_requests_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.repository = const ListingRepository()});

  final ListingRepository repository;

  User? get _user =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sıfır Atık'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Profilim',
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfilePage(repository: repository),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                label: const Text('Profilim'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  side: BorderSide(color: colorScheme.outlineVariant),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useHorizontalLayout = constraints.maxWidth >= 600;
            final createListingCard = _ActionCard(
              icon: Icons.add_photo_alternate_outlined,
              title: 'Atık İlanı Ver',
              description: 'Fotoğraf ekle ve ilanını paylaş.',
              color: colorScheme.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateListingPage(),
                  ),
                );
              },
            );
            final viewListingsCard = _ActionCard(
              icon: Icons.view_list_outlined,
              title: 'İlanları Gör',
              description: 'Çevrendeki atık ilanlarını keşfet.',
              color: colorScheme.secondary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ListingsPage()),
                );
              },
            );
            final myListingsCard = _ActionCard(
              icon: Icons.inventory_2_outlined,
              title: 'İlanlarım',
              description: 'Paylaştığım ilanları yönet.',
              color: colorScheme.tertiary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MyListingsPage(),
                  ),
                );
              },
            );
            final myRequestsCard = _ActionCard(
              icon: Icons.handshake_outlined,
              title: 'Taleplerim',
              description: 'Gönderdiğin talepleri takip et.',
              color: colorScheme.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MyRequestsPage(),
                  ),
                );
              },
            );
            final reportedListingsCard = _ActionCard(
              icon: Icons.flag_outlined,
              title: 'Bildirilen İlanlar',
              description: 'Gelen bildirimleri incele.',
              color: colorScheme.error,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ModerationPage(repository: repository),
                  ),
                );
              },
            );
            final user = _user;

            return SingleChildScrollView(
              padding: responsivePagePadding(context, top: 10),
              child: ResponsiveContent(
                maxWidth: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(colorScheme: colorScheme),
                    const SizedBox(height: 28),
                    Text(
                      'Ne yapmak istersiniz?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (useHorizontalLayout)
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: createListingCard),
                              const SizedBox(width: 16),
                              Expanded(child: viewListingsCard),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: myListingsCard),
                              const SizedBox(width: 16),
                              Expanded(child: myRequestsCard),
                            ],
                          ),
                          if (user != null)
                            FutureBuilder<bool>(
                              future: repository.isModerator(user.uid),
                              builder: (context, snapshot) {
                                if (snapshot.data != true) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: reportedListingsCard,
                                );
                              },
                            ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          createListingCard,
                          const SizedBox(height: 14),
                          viewListingsCard,
                          const SizedBox(height: 14),
                          myListingsCard,
                          const SizedBox(height: 14),
                          myRequestsCard,
                          if (user != null)
                            FutureBuilder<bool>(
                              future: repository.isModerator(user.uid),
                              builder: (context, snapshot) {
                                if (snapshot.data != true) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 14),
                                    reportedListingsCard,
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoş geldiniz',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Atık ilanlarını ve taleplerini buradan takip edebilirsin.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.recycling_rounded,
            color: colorScheme.onPrimary,
            size: 30,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 340;
            final padding = isNarrow ? 15.0 : 17.0;
            final iconSize = isNarrow ? 46.0 : 50.0;

            return InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: isNarrow ? 92 : 96),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Row(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          size: isNarrow ? 24 : 26,
                          color: color,
                        ),
                      ),
                      SizedBox(width: isNarrow ? 12 : 15),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  (isNarrow
                                          ? Theme.of(
                                              context,
                                            ).textTheme.titleSmall
                                          : Theme.of(
                                              context,
                                            ).textTheme.titleMedium)
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.1,
                                      ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
