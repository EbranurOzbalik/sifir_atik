enum ListingRequestStatus { pending, accepted, rejected }

class ListingRequest {
  const ListingRequest({
    required this.id,
    required this.listingId,
    required this.requesterName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String requesterName;
  final ListingRequestStatus status;
  final DateTime createdAt;

  ListingRequest copyWith({ListingRequestStatus? status}) {
    return ListingRequest(
      id: id,
      listingId: listingId,
      requesterName: requesterName,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
