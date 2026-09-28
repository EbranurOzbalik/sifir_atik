import 'package:flutter/material.dart';
import 'package:sifir_atik/models/contribution_summary.dart';
import 'package:sifir_atik/theme/app_theme.dart';

class ContributionCard extends StatelessWidget {
  const ContributionCard({super.key, required this.summary});

  final ContributionSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Katkım',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _description {
    if (!summary.hasContribution) {
      return 'Tamamlanan teslimatların burada görünecek.';
    }

    final deliveryText = '${summary.completedCount} teslimat tamamlandı';
    if (summary.totalKilograms <= 0) return deliveryText;
    return '$deliveryText · ${summary.formattedKilograms} kg değerlendirildi';
  }
}
