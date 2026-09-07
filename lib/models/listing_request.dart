import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingRequestStatus { pending, accepted, rejected }

class ListingRequest {
  const ListingRequest({
    required this.id,
    required this.listingId,
    required this.listingOwnerId,
    required this.listingTitle,
    required this.listingAmount,
    required this.listingLocation,
    required this.requesterId,
    required this.requesterName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String listingOwnerId;
  final String listingTitle;
  final String listingAmount;
  final String listingLocation;
  final String requesterId;
  final String requesterName;
  final ListingRequestStatus status;
  final DateTime createdAt;

  factory ListingRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAtValue = data['createdAt'];
    final statusName = data['status'] as String? ?? 'pending';

    return ListingRequest(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      listingOwnerId: data['listingOwnerId'] as String? ?? '',
      listingTitle: data['listingTitle'] as String? ?? 'İlan bulunamadı',
      listingAmount: data['listingAmount'] as String? ?? '',
      listingLocation: data['listingLocation'] as String? ?? '',
      requesterId: data['requesterId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? 'Kullanıcı',
      status: ListingRequestStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => ListingRequestStatus.pending,
      ),
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
    );
  }

  ListingRequest copyWith({ListingRequestStatus? status}) {
    return ListingRequest(
      id: id,
      listingId: listingId,
      listingOwnerId: listingOwnerId,
      listingTitle: listingTitle,
      listingAmount: listingAmount,
      listingLocation: listingLocation,
      requesterId: requesterId,
      requesterName: requesterName,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'listingOwnerId': listingOwnerId,
      'listingTitle': listingTitle,
      'listingAmount': listingAmount,
      'listingLocation': listingLocation,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
