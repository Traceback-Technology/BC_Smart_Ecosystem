enum AppUserRole { student, staff, guest, unclassified }

class AppSession {
  final AppUserRole role;
  final String? fullName;
  final String? email;
  final String? accessToken;

  const AppSession.student({
    String? fullName,
    String? firstName,
    this.email = 'student@belgiumcampus.ac.za',
    this.accessToken,
  }) : assert(fullName != null || firstName != null),
       fullName = fullName ?? firstName,
       role = AppUserRole.student;

  const AppSession.microsoft({
    required this.fullName,
    required this.email,
    required this.accessToken,
    required String accountType,
  }) : role = accountType == 'student'
           ? AppUserRole.student
           : accountType == 'staff'
           ? AppUserRole.staff
           : AppUserRole.unclassified;

  const AppSession.guest()
    : role = AppUserRole.guest,
      fullName = null,
      email = null,
      accessToken = null;

  bool get isStudent => role == AppUserRole.student;

  bool get isStaff => role == AppUserRole.staff;

  bool get isCampusMember => isStudent || isStaff;

  bool get isGuest => role == AppUserRole.guest;

  String? get firstName {
    final name = fullName?.trim();

    if (name == null || name.isEmpty) {
      return null;
    }

    return name.split(RegExp(r'\s+')).first;
  }

  String get displayName {
    final name = fullName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Guest User';
  }

  String get roleLabel => switch (role) {
    AppUserRole.student => 'Student',
    AppUserRole.staff => 'Staff',
    AppUserRole.guest => 'Guest',
    AppUserRole.unclassified => 'Unclassified',
  };

  String get displayEmail {
    final value = email?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'No campus email';
  }
}
