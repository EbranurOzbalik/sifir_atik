enum AccountType { individual, organization }

extension AccountTypeText on AccountType {
  String get value => switch (this) {
    AccountType.individual => 'individual',
    AccountType.organization => 'organization',
  };

  String get label => switch (this) {
    AccountType.individual => 'Bireysel',
    AccountType.organization => 'Şirket / Kurum',
  };

  String get profileLabel => switch (this) {
    AccountType.individual => 'Bireysel hesap',
    AccountType.organization => 'Şirket / kurum hesabı',
  };

  static AccountType fromValue(Object? value) {
    return value == AccountType.organization.value
        ? AccountType.organization
        : AccountType.individual;
  }
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.accountType,
  });

  final String uid;
  final String displayName;
  final String email;
  final AccountType accountType;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: (data['displayName'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      accountType: AccountTypeText.fromValue(data['accountType']),
    );
  }
}
