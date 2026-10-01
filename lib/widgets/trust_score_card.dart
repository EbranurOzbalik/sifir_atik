import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing_rating.dart';
import 'package:sifir_atik/theme/app_theme.dart';

class TrustScoreCard extends StatelessWidget {
  const TrustScoreCard({super.key, required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2D8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFE09A32),
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Güven puanı',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  summary.hasRatings
                      ? '${summary.formattedAverage} / 5 · ${summary.count} değerlendirme'
                      : 'Henüz değerlendirme yok',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrustScoreLine extends StatelessWidget {
  const TrustScoreLine({super.key, required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          summary.hasRatings ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: const Color(0xFFE09A32),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            summary.hasRatings
                ? '${summary.formattedAverage} (${summary.count} değerlendirme)'
                : 'Henüz değerlendirme yok',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
