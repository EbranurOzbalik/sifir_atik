import 'package:sifir_atik/models/listing.dart';

class ContributionSummary {
  const ContributionSummary({
    required this.completedCount,
    required this.totalKilograms,
  });

  const ContributionSummary.empty() : completedCount = 0, totalKilograms = 0;

  final int completedCount;
  final double totalKilograms;

  factory ContributionSummary.fromListings(Iterable<Listing> listings) {
    final completed = listings
        .where((listing) => listing.status == ListingStatus.completed)
        .toList();

    return ContributionSummary(
      completedCount: completed.length,
      totalKilograms: completed.fold<double>(
        0,
        (total, listing) => total + kilogramsFromAmount(listing.amount),
      ),
    );
  }

  bool get hasContribution => completedCount > 0;

  String get formattedKilograms {
    if (totalKilograms == totalKilograms.roundToDouble()) {
      return totalKilograms.toInt().toString();
    }
    return totalKilograms.toStringAsFixed(1).replaceAll('.', ',');
  }
}

double kilogramsFromAmount(String amount) {
  final normalized = amount.toLowerCase().replaceAll(',', '.');
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
  final value = double.tryParse(match?.group(1) ?? '');
  if (value == null) return 0;

  if (RegExp(r'\b(kg|kilo|kilogram)\b').hasMatch(normalized)) return value;
  if (RegExp(r'\b(g|gr|gram)\b').hasMatch(normalized)) return value / 1000;
  return 0;
}
