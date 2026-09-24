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
    String city = '',
    String contactPersonName = '',
    OrganizationType? organizationType,
  }) async {
    final reference = _database.collection('users').doc(uid);

    await _database.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) {
        final data = snapshot.data() ?? <String, dynamic>{};
        final missingFields = <String, dynamic>{};

        if (!data.containsKey('displayName')) {
          missingFields['displayName'] = displayName.trim();
        }
        if (!data.containsKey('email')) {
          missingFields['email'] = email.trim();
        }
        if (!data.containsKey('accountType')) {
          missingFields['accountType'] = accountType.value;
        }
        if (!data.containsKey('city')) {
          missingFields['city'] = city.trim();
        }
        if (!data.containsKey('contactPersonName')) {
          missingFields['contactPersonName'] =
              accountType == AccountType.organization
              ? contactPersonName.trim()
              : '';
        }
        if (!data.containsKey('organizationType')) {
          missingFields['organizationType'] =
              accountType == AccountType.organization
              ? organizationType?.value ?? OrganizationType.other.value
              : '';
        }
        if (!data.containsKey('isOrganizationVerified')) {
          missingFields['isOrganizationVerified'] = false;
        }

        if (missingFields.isNotEmpty) {
          missingFields['updatedAt'] = FieldValue.serverTimestamp();
          transaction.update(reference, missingFields);
        }
        return;
      }

      transaction.set(reference, {
        'displayName': displayName.trim(),
        'email': email.trim(),
        'accountType': accountType.value,
        'city': city.trim(),
        'contactPersonName': accountType == AccountType.organization
            ? contactPersonName.trim()
            : '',
        'organizationType': accountType == AccountType.organization
            ? organizationType?.value ?? OrganizationType.other.value
            : '',
        'isOrganizationVerified': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
