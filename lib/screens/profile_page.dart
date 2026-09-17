import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/services/auth_service.dart';
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

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Hesabımı sil'),
        content: const Text(
          'Bu işlem geri alınamaz. Firebase giriş hesabınız kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Hesabı Kalıcı Olarak Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await AuthService().deleteCurrentAccount();
      await const SessionPreferences().clearRememberMe();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on AuthServiceException catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = _user;
    final displayName = user?.displayName?.trim();
    final email = user?.email ?? 'Giriş yapılmadı';
    final moderatorFuture = user == null
        ? Future<bool>.value(false)
        : repository.isModerator(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: moderatorFuture,
          builder: (context, snapshot) {
            final isModerator = snapshot.data == true;

            return ListView(
              padding: responsivePagePadding(context, top: 20),
              children: [
                ResponsiveContent(
                  child: _ProfileHeader(
                    displayName: displayName?.isNotEmpty == true
                        ? displayName!
                        : 'Profilim',
                    email: email,
                    isModerator: isModerator,
                  ),
                ),
                const SizedBox(height: 24),
                ResponsiveContent(
                  child: Text(
                    'HESAP AYARLARI',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 12),
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
                if (isModerator) ...[
                  const SizedBox(height: 12),
                  ResponsiveContent(
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
                  ),
                ],
                const SizedBox(height: 24),
                ResponsiveContent(
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _signOut(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ResponsiveContent(
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _deleteAccount(context),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hesabımı Sil'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.isModerator,
  });

  final String displayName;
  final String email;
  final bool isModerator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person_outline_rounded,
              size: 30,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
                if (isModerator) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Moderatör hesabı',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
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
