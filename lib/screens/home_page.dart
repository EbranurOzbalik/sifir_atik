import 'package:flutter/material.dart';

import 'create_listing_page.dart';
import 'listings_page.dart';
import 'my_listings_page.dart';
import 'my_requests_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sıfır Atık'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            tooltip: 'Profilim',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.person_outline),
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
              description:
                  'Değerlendirilebilir atıklarınız için yeni bir ilan oluşturun.',
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
              description: 'Paylaşılan atık ilanlarını keşfedin ve inceleyin.',
              color: colorScheme.tertiary,
              backgroundColor: colorScheme.tertiaryContainer,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ListingsPage()),
                );
              },
            );
            final myListingsCard = _ActionCard(
              icon: Icons.inventory_2_outlined,
              title: 'İlanlarım',
              description: 'Paylaştığım ilanları ve gelen talepleri takip et.',
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
              description: 'İlgilendiğim ilanların son durumunu gör.',
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
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WelcomeSection(colorScheme: colorScheme),
                      const SizedBox(height: 32),
                      Text(
                        'Ne yapmak istersiniz?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                            viewListingsCard,
                            const SizedBox(height: 16),
                            myListingsCard,
                            const SizedBox(height: 16),
                            myRequestsCard,
                          ],
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

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/zero_waste_logo.png',
              semanticLabel: 'Sıfır atık logosu',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldiniz!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Atıkları birlikte dönüştürelim, geleceği birlikte koruyalım.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_rounded, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
