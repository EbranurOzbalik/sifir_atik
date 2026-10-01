import 'package:cloud_firestore/cloud_firestore.dart';

class ListingRating {
  const ListingRating({
    required this.id,
    required this.requestId,
    required this.listingId,
    required this.listingTitle,
    required this.ratedUserId,
    required this.raterUserId,
    required this.raterName,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String listingId;
  final String listingTitle;
  final String ratedUserId;
  final String raterUserId;
  final String raterName;
  final int score;
  final String comment;
  final DateTime createdAt;

  factory ListingRating.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];

    return ListingRating(
      id: doc.id,
      requestId: data['requestId'] as String? ?? '',
      listingId: data['listingId'] as String? ?? '',
      listingTitle: data['listingTitle'] as String? ?? '',
      ratedUserId: data['ratedUserId'] as String? ?? '',
      raterUserId: data['raterUserId'] as String? ?? '',
      raterName: data['raterName'] as String? ?? 'Kullanıcı',
      score: (data['score'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'ratedUserId': ratedUserId,
      'raterUserId': raterUserId,
      'raterName': raterName,
      'score': score,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class RatingSummary {
  const RatingSummary({required this.average, required this.count});

  const RatingSummary.empty() : average = 0, count = 0;

  final double average;
  final int count;

  bool get hasRatings => count > 0;

  String get formattedAverage => average.toStringAsFixed(1);

  factory RatingSummary.fromRatings(List<ListingRating> ratings) {
    if (ratings.isEmpty) return const RatingSummary.empty();

    final total = ratings.fold<int>(0, (sum, rating) => sum + rating.score);
    return RatingSummary(
      average: total / ratings.length,
      count: ratings.length,
    );
  }
}
