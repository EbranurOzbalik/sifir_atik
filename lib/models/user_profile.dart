enum AccountType { individual, organization }

enum OrganizationType { company, municipality, association, education, other }

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

extension OrganizationTypeText on OrganizationType {
  String get value => switch (this) {
    OrganizationType.company => 'company',
    OrganizationType.municipality => 'municipality',
    OrganizationType.association => 'association',
    OrganizationType.education => 'education',
    OrganizationType.other => 'other',
  };

  String get label => switch (this) {
    OrganizationType.company => 'Şirket',
    OrganizationType.municipality => 'Belediye',
    OrganizationType.association => 'Dernek / Vakıf',
    OrganizationType.education => 'Eğitim kurumu',
    OrganizationType.other => 'Diğer',
  };

  static OrganizationType? fromValue(Object? value) {
    for (final type in OrganizationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.accountType,
    this.city = '',
    this.contactPersonName = '',
    this.organizationType,
    this.isOrganizationVerified = false,
  });

  final String uid;
  final String displayName;
  final String email;
  final AccountType accountType;
  final String city;
  final String contactPersonName;
  final OrganizationType? organizationType;
  final bool isOrganizationVerified;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: (data['displayName'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      accountType: AccountTypeText.fromValue(data['accountType']),
      city: (data['city'] as String?)?.trim() ?? '',
      contactPersonName: (data['contactPersonName'] as String?)?.trim() ?? '',
      organizationType: OrganizationTypeText.fromValue(
        data['organizationType'],
      ),
      isOrganizationVerified: data['isOrganizationVerified'] as bool? ?? false,
    );
  }
}
