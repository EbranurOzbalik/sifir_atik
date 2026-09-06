import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingRequestStatus { pending, accepted, rejected }

class ListingRequest {
  const ListingRequest({
    required this.id,
    required this.listingId,
    required this.requesterId,
    required this.requesterName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String requesterId;
  final String requesterName;
  final ListingRequestStatus status;
  final DateTime createdAt;

  ListingRequest copyWith({ListingRequestStatus? status}) {
    return ListingRequest(
      id: id,
      listingId: listingId,
      requesterId: requesterId,
      requesterName: requesterName,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
