import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/services/listing_repository.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({
    super.key,
    this.repository = const ListingRepository(),
    this.currentUserId,
    this.isFirebaseReady,
  });

  final ListingRepository repository;
  final String? currentUserId;
  final bool? isFirebaseReady;

  bool get _hasFirebase => isFirebaseReady ?? Firebase.apps.isNotEmpty;

  User? get _user => _hasFirebase && Firebase.apps.isNotEmpty
      ? FirebaseAuth.instance.currentUser
      : null;

  String? get _userId => currentUserId ?? _user?.uid;

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Taleplerim')),
      body: SafeArea(
        child: userId == null
            ? const _EmptyState(
                icon: Icons.lock_outline,
                title: 'Giriş bulunamadı',
                message: 'Taleplerinizi görmek için giriş yapmalısınız.',
              )
            : StreamBuilder<List<ListingRequest>>(
                stream: repository.watchRequestsByRequester(userId),
                builder: (context, requestsSnapshot) {
                  final requests = requestsSnapshot.data ?? const [];

                  if (requests.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.handshake_outlined,
                      title: 'Henüz talebim yok',
                      message:
                          'Bir ilana ilgileniyorum dediğinizde burada görünecek.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = requests[index];

                      return _RequestCard(
                        request: request,
                        listingTitle: request.listingTitle,
                        listingInfo:
                            '${request.listingAmount} • ${request.listingLocation}',
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.listingTitle,
    required this.listingInfo,
  });

  final ListingRequest request;
  final String listingTitle;
  final String listingInfo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusInfo = _statusInfo(request.status);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusInfo.icon, color: statusInfo.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    listingTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              listingInfo,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(statusInfo.label),
              avatar: Icon(statusInfo.icon, size: 18),
              backgroundColor: statusInfo.color.withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
            if (request.status == ListingRequestStatus.accepted &&
                request.ownerContactInfo.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_outlined, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'İlan sahibinin iletişimi: ${request.ownerContactInfo}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusInfo {
  const _StatusInfo(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

_StatusInfo _statusInfo(ListingRequestStatus status) {
  return switch (status) {
    ListingRequestStatus.accepted => const _StatusInfo(
      'Kabul edildi',
      Icons.check_circle_outline,
      Color(0xFF2E7D32),
    ),
    ListingRequestStatus.rejected => const _StatusInfo(
      'Reddedildi',
      Icons.cancel_outlined,
      Color(0xFFC62828),
    ),
    ListingRequestStatus.pending => const _StatusInfo(
      'Beklemede',
      Icons.hourglass_top_outlined,
      Color(0xFFF57C00),
    ),
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
