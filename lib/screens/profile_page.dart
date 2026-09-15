import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/session_preferences.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

import 'login_page.dart';
import 'moderation_page.dart';
import 'my_listings_page.dart';
import 'my_requests_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.repository = const ListingRepository()});

  final ListingRepository repository;

  User? get _user =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

  Future<void> _signOut(BuildContext context) async {
    await const SessionPreferences().clearRememberMe();

    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = _user;
    final displayName = user?.displayName?.trim();
    final email = user?.email ?? 'Giriş yapılmadı';

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: SafeArea(
        child: ListView(
          padding: responsivePagePadding(context, top: 20),
          children: [
            ResponsiveContent(
              child: Card(
                elevation: 0,
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.primary,
                        child: Icon(
                          Icons.person_outline,
                          size: 34,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName?.isNotEmpty == true
                                  ? displayName!
                                  : 'Profilim',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveContent(
              child: _ProfileTile(
                icon: Icons.inventory_2_outlined,
                title: 'İlanlarım',
                description: 'Paylaştığım ilanları ve gelen talepleri gör.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyListingsPage(),
                    ),
                  );
                },
              ),
            ),
            ResponsiveContent(
              child: _ProfileTile(
                icon: Icons.handshake_outlined,
                title: 'Taleplerim',
                description: 'İlgilendiğim ilanların durumunu takip et.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyRequestsPage(),
                    ),
                  );
                },
              ),
            ),
            if (user != null)
              FutureBuilder<bool>(
                future: repository.isModerator(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.data != true) {
                    return const SizedBox.shrink();
                  }

                  return ResponsiveContent(
                    child: _ProfileTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Moderatör Paneli',
                      description: 'Bildirilen ilanları incele.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ModerationPage(repository: repository),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            ResponsiveContent(
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
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

    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(description),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
