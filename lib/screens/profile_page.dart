import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';
import 'my_listings_page.dart';
import 'my_requests_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  User? get _user =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

  Future<void> _signOut(BuildContext context) async {
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
          padding: const EdgeInsets.all(24),
          children: [
            Card(
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
            const SizedBox(height: 16),
            _ProfileTile(
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
            _ProfileTile(
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
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
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
