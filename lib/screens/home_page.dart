import 'package:flutter/material.dart';

import 'create_listing_page.dart';
import 'listings_page.dart';
import 'my_listings_page.dart';
import 'my_requests_page.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sıfır Atık')),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.28),
                colorScheme.surface,
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useHorizontalLayout = constraints.maxWidth >= 600;
              final createListingCard = _ActionCard(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Atık İlanı Ver',
                description: 'Fotoğraf ekle ve ilanını paylaş.',
                color: colorScheme.primary,
                backgroundColor: colorScheme.primaryContainer,
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
                color: colorScheme.tertiary,
                backgroundColor: colorScheme.tertiaryContainer,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ListingsPage(),
                    ),
                  );
                },
              );
              final myListingsCard = _ActionCard(
                icon: Icons.inventory_2_outlined,
                title: 'İlanlarım',
                description: 'Paylaştığım ilanları yönet.',
                color: colorScheme.secondary,
                backgroundColor: colorScheme.secondaryContainer,
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
                backgroundColor: colorScheme.primaryContainer,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyRequestsPage(),
                    ),
                  );
                },
              );

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
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
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
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.75),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.recycling_rounded,
            color: colorScheme.primary,
            size: 34,
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
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor.withValues(alpha: 0.88),
                colorScheme.surfaceContainerLow,
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final padding = isNarrow ? 16.0 : 20.0;
              final iconSize = isNarrow ? 48.0 : 56.0;
              final arrowSize = isNarrow ? 32.0 : 36.0;

              return InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: isNarrow ? 100 : 108),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      children: [
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(
                              isNarrow ? 16 : 18,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: isNarrow ? 26 : 30,
                            color: color,
                          ),
                        ),
                        SizedBox(width: isNarrow ? 12 : 16),
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
                                        ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isNarrow ? 8 : 12),
                        Container(
                          width: arrowSize,
                          height: arrowSize,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
