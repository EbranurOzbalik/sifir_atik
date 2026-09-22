import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sifir_atik/models/user_profile.dart';

class UserProfileRepository {
  const UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get _isReady => _firestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore get _database => _firestore ?? FirebaseFirestore.instance;

  Future<UserProfile?> getProfile(String uid) async {
    if (!_isReady) return null;

    final snapshot = await _database.collection('users').doc(uid).get();
    final data = snapshot.data();
    return data == null ? null : UserProfile.fromMap(snapshot.id, data);
  }

  Future<void> createProfileIfMissing({
    required String uid,
    required String displayName,
    required String email,
    required AccountType accountType,
  }) async {
    final reference = _database.collection('users').doc(uid);

    await _database.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) return;

      transaction.set(reference, {
        'displayName': displayName.trim(),
        'email': email.trim(),
        'accountType': accountType.value,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
