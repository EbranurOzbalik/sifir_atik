import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/services/listing_repository.dart';

import 'create_listing_page.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  static const _repository = ListingRepository();

  User? get _user =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      appBar: AppBar(title: const Text('İlanlarım')),
      body: SafeArea(
        child: user == null
            ? const _EmptyState(
                icon: Icons.lock_outline,
                title: 'Giriş bulunamadı',
                message: 'İlanlarınızı görmek için giriş yapmalısınız.',
              )
            : StreamBuilder<List<Listing>>(
                stream: _repository.watchMyListings(user.uid),
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
                    stream: _repository.watchRequestsByListingOwner(user.uid),
                    builder: (context, requestsSnapshot) {
                      final requests = requestsSnapshot.data ?? const [];

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: listings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final listing = listings[index];
                          final listingRequests = requests
                              .where(
                                (request) => request.listingId == listing.id,
                              )
                              .toList();

                          return _MyListingCard(
                            listing: listing,
                            requests: listingRequests,
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
  const _MyListingCard({required this.listing, required this.requests});

  final Listing listing;
  final List<ListingRequest> requests;

  Future<void> _changeStatus(
    BuildContext context,
    ListingRequest request,
    ListingRequestStatus status,
  ) async {
    final isSaved = await MyListingsPage._repository.updateRequestStatus(
      request.id,
      status,
    );

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

    final isDeleted = await MyListingsPage._repository.deleteListing(listing);

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

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${listing.amount} • ${listing.location}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
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
            ),
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
            if (requests.isNotEmpty) ...[
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
              label: Text(
                request.status == ListingRequestStatus.accepted
                    ? 'Kabul edildi'
                    : 'Reddedildi',
              ),
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }
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
