import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/models/user_profile.dart';
import 'package:sifir_atik/theme/app_theme.dart';
import 'package:sifir_atik/services/location_service.dart';

class ListingPreviewCard extends StatelessWidget {
  const ListingPreviewCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.request,
    this.distanceKm,
  });

  final Listing listing;
  final ListingRequest? request;
  final double? distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = listingCategoryColor(listing.category);

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ListingImageView(
                      listing: listing,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(19),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _Badge(
                        label: listing.category,
                        color: categoryColor,
                      ),
                    ),
                    if (listing.ownerAccountType == AccountType.organization)
                      Positioned(
                        left: 10,
                        top: 48,
                        child: _Badge(
                          label: listing.isOwnerVerified
                              ? 'Doğrulanmış kurum'
                              : 'Kurumsal',
                          color: colorScheme.primary,
                          icon: listing.isOwnerVerified
                              ? Icons.verified_rounded
                              : Icons.apartment_rounded,
                        ),
                      ),
                    if (request != null)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _Badge(
                          label: requestStatusLabel(request!.status),
                          color: requestStatusColor(request!.status),
                        ),
                      ),
                    if (distanceKm != null)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: _Badge(
                          label: formatDistance(distanceKm!),
                          color: colorScheme.primary,
                          icon: Icons.near_me_rounded,
                        ),
                      ),
                  ],
                ),
              ),
              Ink(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.scale_outlined,
                            size: 15,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${listing.amount} • ${listing.location}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListingImageView extends StatelessWidget {
  const ListingImageView({
    super.key,
    required this.listing,
    required this.borderRadius,
    this.padding = const EdgeInsets.all(18),
  });

  final Listing listing;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.imageUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: imageUrl == null || imageUrl.isEmpty
          ? Container(
              color: listingCategoryColor(
                listing.category,
              ).withValues(alpha: 0.12),
              padding: padding,
              child: SvgPicture.asset(
                listing.imageAsset,
                fit: BoxFit.contain,
                semanticsLabel: listing.title,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: listingCategoryColor(
                    listing.category,
                  ).withValues(alpha: 0.12),
                  padding: padding,
                  child: SvgPicture.asset(
                    listing.imageAsset,
                    fit: BoxFit.contain,
                    semanticsLabel: listing.title,
                  ),
                );
              },
            ),
    );
  }
}

Color listingCategoryColor(String category) {
  return switch (category) {
    'Kağıt' => const Color(0xFFB96F3E),
    'Plastik' => const Color(0xFF2F8073),
    'Cam' => const Color(0xFF776CB3),
    'Metal' => const Color(0xFF61727E),
    'Elektronik' => const Color(0xFFD45D52),
    'Tekstil' => const Color(0xFFB45E83),
    'Organik' => const Color(0xFF528457),
    'Pil' => const Color(0xFFD47A38),
    'Atık Yağ' => const Color(0xFF9A7931),
    'Ahşap' => const Color(0xFF8A6045),
    _ => AppColors.forest,
  };
}

String requestStatusLabel(ListingRequestStatus status) {
  return switch (status) {
    ListingRequestStatus.accepted => 'Kabul edildi',
    ListingRequestStatus.rejected => 'Reddedildi',
    ListingRequestStatus.pending => 'Beklemede',
  };
}

Color requestStatusColor(ListingRequestStatus status) {
  return switch (status) {
    ListingRequestStatus.accepted => const Color(0xFF2E7D32),
    ListingRequestStatus.rejected => const Color(0xFFC62828),
    ListingRequestStatus.pending => const Color(0xFFC86C00),
  };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
