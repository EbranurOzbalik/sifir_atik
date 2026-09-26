import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/user_profile.dart';
import 'package:sifir_atik/services/auth_service.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/notification_service.dart';
import 'package:sifir_atik/services/session_preferences.dart';
import 'package:sifir_atik/services/user_profile_repository.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

import 'login_page.dart';
import 'moderation_page.dart';
import 'my_listings_page.dart';
import 'my_requests_page.dart';
import 'notifications_page.dart';
import 'saved_listings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.repository = const ListingRepository(),
    this.profileRepository = const UserProfileRepository(),
    this.embedded = false,
  });

  final ListingRepository repository;
  final UserProfileRepository profileRepository;
  final bool embedded;

  User? get _user =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

  Future<void> _signOut(BuildContext context) async {
    await const SessionPreferences().clearRememberMe();

    if (Firebase.apps.isNotEmpty) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await NotificationService.instance.unregister(userId);
      }
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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await NotificationService.instance.unregister(userId);
      }
      await AuthService().deleteCurrentAccount();
      await const SessionPreferences().clearRememberMe();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on AuthServiceException catch (error) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await NotificationService.instance.initialize(userId);
      }
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
    final profileFuture = user == null
        ? Future<UserProfile?>.value(null)
        : profileRepository.getProfile(user.uid);

    final content = SafeArea(
      child: FutureBuilder<bool>(
        future: moderatorFuture,
        builder: (context, snapshot) {
          final isModerator = snapshot.data == true;

          return ListView(
            padding: responsivePagePadding(context, top: 20),
            children: [
              if (embedded) ...[
                ResponsiveContent(
                  child: Text(
                    'Profilim',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              ResponsiveContent(
                child: FutureBuilder<UserProfile?>(
                  future: profileFuture,
                  builder: (context, profileSnapshot) {
                    final profile = profileSnapshot.data;
                    final profileName = profile?.displayName.trim();

                    return _ProfileHeader(
                      displayName: profileName?.isNotEmpty == true
                          ? profileName!
                          : displayName?.isNotEmpty == true
                          ? displayName!
                          : 'Profilim',
                      email: profile?.email.isNotEmpty == true
                          ? profile!.email
                          : email,
                      accountType:
                          profile?.accountType ?? AccountType.individual,
                      city: profile?.city ?? '',
                      contactPersonName: profile?.contactPersonName ?? '',
                      organizationType: profile?.organizationType,
                      isOrganizationVerified:
                          profile?.isOrganizationVerified ?? false,
                      isModerator: isModerator,
                    );
                  },
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
                  icon: Icons.notifications_none_rounded,
                  title: 'Bildirimler',
                  description: 'Talep ve ilan bildirimlerini gör.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ResponsiveContent(
                child: _ProfileTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Kaydedilenler',
                  description: 'Daha sonra bakmak için kaydettiğim ilanlar.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SavedListingsPage(repository: repository),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
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
    );

    if (embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: content,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.accountType,
    required this.city,
    required this.contactPersonName,
    required this.organizationType,
    required this.isOrganizationVerified,
    required this.isModerator,
  });

  final String displayName;
  final String email;
  final AccountType accountType;
  final String city;
  final String contactPersonName;
  final OrganizationType? organizationType;
  final bool isOrganizationVerified;
  final bool isModerator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              accountType == AccountType.organization
                  ? Icons.apartment_rounded
                  : Icons.person_outline_rounded,
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
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                if (accountType == AccountType.organization &&
                    contactPersonName.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Yetkili: $contactPersonName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (city.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProfileBadge(
                      icon: accountType == AccountType.organization
                          ? Icons.apartment_outlined
                          : Icons.person_outline,
                      label: accountType.profileLabel,
                    ),
                    if (accountType == AccountType.organization &&
                        organizationType != null)
                      _ProfileBadge(
                        icon: Icons.domain_outlined,
                        label: organizationType!.label,
                      ),
                    if (accountType == AccountType.organization)
                      _ProfileBadge(
                        icon: isOrganizationVerified
                            ? Icons.verified_rounded
                            : Icons.schedule_rounded,
                        label: isOrganizationVerified
                            ? 'Doğrulanmış kurum'
                            : 'Doğrulama bekliyor',
                      ),
                    if (isModerator)
                      const _ProfileBadge(
                        icon: Icons.verified_user_outlined,
                        label: 'Moderatör',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
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
      color: Colors.white,
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
