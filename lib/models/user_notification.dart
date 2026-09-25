import 'package:cloud_firestore/cloud_firestore.dart';

enum UserNotificationType {
  requestReceived,
  requestAccepted,
  requestRejected,
  general,
}

class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.listingId = '',
    this.requestId = '',
  });

  final String id;
  final String title;
  final String body;
  final UserNotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String listingId;
  final String requestId;

  factory UserNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    final createdAt = data['createdAt'];
    final typeName = data['type'] as String? ?? '';

    return UserNotification(
      id: document.id,
      title: data['title'] as String? ?? 'Sıfır Atık',
      body: data['body'] as String? ?? '',
      type: UserNotificationType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => UserNotificationType.general,
      ),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      listingId: data['listingId'] as String? ?? '',
      requestId: data['requestId'] as String? ?? '',
    );
  }
}
