import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/user_notification.dart';
import 'package:sifir_atik/screens/my_listings_page.dart';
import 'package:sifir_atik/screens/my_requests_page.dart';
import 'package:sifir_atik/services/notification_repository.dart';
import 'package:sifir_atik/theme/app_theme.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    this.repository = const NotificationRepository(),
    this.currentUserId,
  });

  final NotificationRepository repository;
  final String? currentUserId;

  String? get _userId {
    if (currentUserId != null) return currentUserId;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (userId != null)
            TextButton(
              onPressed: () => repository.markAllAsRead(userId),
              child: const Text('Tümünü oku'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: userId == null
            ? const _EmptyNotifications(message: 'Giriş yapılmadı.')
            : StreamBuilder<List<UserNotification>>(
                stream: repository.watchNotifications(userId),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? const [];
                  if (notifications.isEmpty) {
                    return const _EmptyNotifications(
                      message: 'Henüz bir bildirimin yok.',
                    );
                  }

                  return ListView.separated(
                    padding: responsivePagePadding(context, top: 16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ResponsiveContent(
                        child: _NotificationTile(
                          notification: notification,
                          onTap: () =>
                              _openNotification(context, userId, notification),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    String userId,
    UserNotification notification,
  ) async {
    if (!notification.isRead) {
      await repository.markAsRead(userId, notification.id);
    }
    if (!context.mounted) return;

    final page = notification.type == UserNotificationType.requestReceived
        ? const MyListingsPage()
        : const MyRequestsPage();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.userId,
    required this.onPressed,
    this.repository = const NotificationRepository(),
  });

  final String? userId;
  final VoidCallback onPressed;
  final NotificationRepository repository;

  @override
  Widget build(BuildContext context) {
    final id = userId;
    return StreamBuilder<int>(
      stream: id == null ? Stream.value(0) : repository.watchUnreadCount(id),
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: IconButton(
            tooltip: 'Bildirimler',
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.forest,
              fixedSize: const Size.square(44),
            ),
            icon: const Icon(Icons.notifications_none_rounded, size: 25),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final UserNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _notificationColor(notification.type, colorScheme);

    return Material(
      color: notification.isRead
          ? colorScheme.surface
          : colorScheme.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.12),
                foregroundColor: accent,
                child: Icon(_notificationIcon(notification.type)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dateLabel(notification.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 52,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}

IconData _notificationIcon(UserNotificationType type) {
  return switch (type) {
    UserNotificationType.requestReceived => Icons.handshake_outlined,
    UserNotificationType.requestAccepted => Icons.check_circle_outline,
    UserNotificationType.requestRejected => Icons.cancel_outlined,
    UserNotificationType.general => Icons.notifications_none_rounded,
  };
}

Color _notificationColor(UserNotificationType type, ColorScheme colorScheme) {
  return switch (type) {
    UserNotificationType.requestAccepted => const Color(0xFF2E7D32),
    UserNotificationType.requestRejected => colorScheme.error,
    _ => colorScheme.primary,
  };
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} · $hour:$minute';
}
