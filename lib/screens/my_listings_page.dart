import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

import 'create_listing_page.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({
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
      appBar: AppBar(title: const Text('İlanlarım')),
      body: SafeArea(
        child: userId == null
            ? const _EmptyState(
                icon: Icons.lock_outline,
                title: 'Giriş bulunamadı',
                message: 'İlanlarınızı görmek için giriş yapmalısınız.',
              )
            : StreamBuilder<List<Listing>>(
                stream: repository.watchMyListings(userId),
                builder: (context, listingsSnapshot) {
                  final listings = listingsSnapshot.data ?? const [];

                  if (listings.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Henüz ilanım yok',
                      message:
                          'Atık ilanı oluşturduğunuzda burada listelenecek.',
                    );
                  }

                  return StreamBuilder<List<ListingRequest>>(
                    stream: repository.watchRequestsByListingOwner(userId),
                    builder: (context, requestsSnapshot) {
                      final requests = requestsSnapshot.data ?? const [];

                      return ListView.separated(
                        padding: responsivePagePadding(context, top: 20),
                        itemCount: listings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final listing = listings[index];
                          final listingRequests = requests
                              .where(
                                (request) => request.listingId == listing.id,
                              )
                              .toList();

                          return ResponsiveContent(
                            child: _MyListingCard(
                              listing: listing,
                              requests: listingRequests,
                              repository: repository,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  const _MyListingCard({
    required this.listing,
    required this.requests,
    required this.repository,
  });

  final Listing listing;
  final List<ListingRequest> requests;
  final ListingRepository repository;

  ListingRequest? get _acceptedRequest {
    for (final request in requests) {
      if (request.id == listing.acceptedRequestId) return request;
    }
    for (final request in requests) {
      if (request.status == ListingRequestStatus.accepted ||
          request.status == ListingRequestStatus.completed) {
        return request;
      }
    }
    return null;
  }

  Future<void> _changeStatus(
    BuildContext context,
    ListingRequest request,
    ListingRequestStatus status,
  ) async {
    final isSaved = await repository.updateRequestStatus(request.id, status);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isSaved ? 'Talep güncellendi.' : 'Talep güncellenemedi.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _deleteListing(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İlan silinsin mi?'),
          content: Text(
            '${listing.title} ilanı ve bu ilana gelen talepler silinecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final isDeleted = await repository.deleteListing(listing);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(isDeleted ? 'İlan silindi.' : 'İlan silinemedi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _completeListing(BuildContext context) async {
    final request = _acceptedRequest;
    if (request == null) return;

    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Teslimat tamamlandı mı?'),
          content: Text(
            '${listing.title} ilanı tamamlananlara taşınacak ve yeni talep alamayacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Teslim Edildi'),
            ),
          ],
        );
      },
    );

    if (shouldComplete != true) return;

    final isCompleted = await repository.completeListing(
      listingId: listing.id,
      requestId: request.id,
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isCompleted
                ? 'Teslimat tamamlandı. Katkınıza eklendi.'
                : 'Teslimat tamamlanamadı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _editListing(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateListingPage(listing: listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _listingStatusColor(listing.status);
    final acceptedRequest = _acceptedRequest;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    listing.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _listingStatusLabel(listing.status),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${listing.amount} • ${listing.location}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (listing.status == ListingStatus.active)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editListing(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Düzenle'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteListing(context),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Sil'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteListing(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('İlanı Sil'),
                ),
              ),
            if (listing.status == ListingStatus.active) ...[
              const SizedBox(height: 12),
              Text(
                requests.isEmpty
                    ? 'Bu ilana henüz talep gelmedi.'
                    : '${requests.length} talep var',
                style: TextStyle(
                  color: requests.isEmpty
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (listing.status == ListingStatus.active &&
                requests.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final request in requests)
                _IncomingRequestTile(
                  request: request,
                  onAccept: () => _changeStatus(
                    context,
                    request,
                    ListingRequestStatus.accepted,
                  ),
                  onReject: () => _changeStatus(
                    context,
                    request,
                    ListingRequestStatus.rejected,
                  ),
                ),
            ],
            if (listing.status == ListingStatus.reserved &&
                acceptedRequest != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${acceptedRequest.requesterName} için ayrıldı. Teslim gerçekleştikten sonra işlemi tamamlayabilirsiniz.',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _completeListing(context),
                  icon: const Icon(Icons.recycling_rounded),
                  label: const Text('Teslim Edildi'),
                ),
              ),
            ],
            if (listing.status == ListingStatus.completed) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.eco_outlined, color: statusColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        listing.completedAt == null
                            ? 'Bu teslimat katkınıza eklendi.'
                            : '${_formatDate(listing.completedAt!)} tarihinde tamamlandı ve katkınıza eklendi.',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
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

class _IncomingRequestTile extends StatelessWidget {
  const _IncomingRequestTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  final ListingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canAnswer = request.status == ListingRequestStatus.pending;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${request.requesterName} ilanınızla ilgileniyor.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (canAnswer)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('Kabul Et'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reddet'),
                  ),
                ),
              ],
            )
          else
            Chip(
              label: Text(switch (request.status) {
                ListingRequestStatus.accepted => 'Kabul edildi',
                ListingRequestStatus.rejected => 'Reddedildi',
                ListingRequestStatus.completed => 'Tamamlandı',
                ListingRequestStatus.pending => 'Beklemede',
              }),
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }
}

String _listingStatusLabel(ListingStatus status) {
  return switch (status) {
    ListingStatus.active => 'Aktif',
    ListingStatus.reserved => 'Ayrıldı',
    ListingStatus.completed => 'Tamamlandı',
  };
}

Color _listingStatusColor(ListingStatus status) {
  return switch (status) {
    ListingStatus.active => const Color(0xFF2E7D32),
    ListingStatus.reserved => const Color(0xFFC86C00),
    ListingStatus.completed => const Color(0xFF347A65),
  };
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
