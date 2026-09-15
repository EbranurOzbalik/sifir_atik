import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingReportStatus { open, resolved }

class ListingReport {
  const ListingReport({
    required this.id,
    required this.listingId,
    required this.listingOwnerId,
    required this.listingTitle,
    required this.listingAmount,
    required this.listingLocation,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String listingOwnerId;
  final String listingTitle;
  final String listingAmount;
  final String listingLocation;
  final String reporterId;
  final String reporterName;
  final String reason;
  final ListingReportStatus status;
  final DateTime createdAt;

  factory ListingReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAtValue = data['createdAt'];
    final statusName = data['status'] as String? ?? 'open';

    return ListingReport(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      listingOwnerId: data['listingOwnerId'] as String? ?? '',
      listingTitle: data['listingTitle'] as String? ?? 'İlan bulunamadı',
      listingAmount: data['listingAmount'] as String? ?? '',
      listingLocation: data['listingLocation'] as String? ?? '',
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? 'Kullanıcı',
      reason: data['reason'] as String? ?? 'Uygunsuz ilan',
      status: ListingReportStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => ListingReportStatus.open,
      ),
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'listingOwnerId': listingOwnerId,
      'listingTitle': listingTitle,
      'listingAmount': listingAmount,
      'listingLocation': listingLocation,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
