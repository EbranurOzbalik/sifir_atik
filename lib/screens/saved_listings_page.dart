import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/widgets/listing_preview_card.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

import 'listings_page.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({
    super.key,
    this.repository = const ListingRepository(),
    this.currentUserId,
    this.isFirebaseReady,
  });

  final ListingRepository repository;
  final String? currentUserId;
  final bool? isFirebaseReady;

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  final Set<String> _updatingListingIds = {};

  bool get _hasFirebase => widget.isFirebaseReady ?? Firebase.apps.isNotEmpty;

  String? get _currentUserId =>
      widget.currentUserId ??
      (_hasFirebase && Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser?.uid
          : null);

  Future<void> _removeSavedListing(Listing listing) async {
    final userId = _currentUserId;
    if (userId == null || _updatingListingIds.contains(listing.id)) return;

    setState(() => _updatingListingIds.add(listing.id));
    final isUpdated = await widget.repository.setListingSaved(
      userId: userId,
      listingId: listing.id,
      isSaved: false,
    );
    if (!mounted) return;
    setState(() => _updatingListingIds.remove(listing.id));

    if (!isUpdated) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('İlan kaydedilenlerden çıkarılamadı.')),
        );
    }
  }

  void _openDetail(Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingDetailPage(
          listing: listing,
          repository: widget.repository,
          currentUserId: _currentUserId,
          isFirebaseReady: _hasFirebase,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Kaydedilenler')),
      body: SafeArea(
        child: userId == null
            ? const _SavedListingsEmpty(
                title: 'Giriş bulunamadı',
                description: 'Kaydettiğiniz ilanları görmek için giriş yapın.',
              )
            : StreamBuilder<Set<String>>(
                stream: widget.repository.watchSavedListingIds(userId),
                builder: (context, savedSnapshot) {
                  if (!savedSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final savedIds = savedSnapshot.data!;
                  return StreamBuilder<List<Listing>>(
                    stream: widget.repository.watchListings(),
                    builder: (context, listingsSnapshot) {
                      if (!listingsSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final savedListings = listingsSnapshot.data!
                          .where((listing) => savedIds.contains(listing.id))
                          .toList();

                      if (savedListings.isEmpty) {
                        return const _SavedListingsEmpty(
                          title: 'Henüz kaydedilen ilan yok',
                          description:
                              'Daha sonra bakmak istediğiniz ilanları kaydedebilirsiniz.',
                        );
                      }

                      return GridView.builder(
                        padding: responsivePagePadding(
                          context,
                          top: 20,
                          bottom: 28,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 270,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: savedListings.length,
                        itemBuilder: (context, index) {
                          final listing = savedListings[index];
                          return ListingPreviewCard(
                            listing: listing,
                            isSaved: true,
                            onSave: _updatingListingIds.contains(listing.id)
                                ? null
                                : () => _removeSavedListing(listing),
                            onTap: () => _openDetail(listing),
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

class _SavedListingsEmpty extends StatelessWidget {
  const _SavedListingsEmpty({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ResponsiveContent(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 54,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
