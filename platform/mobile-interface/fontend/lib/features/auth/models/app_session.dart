enum AppUserRole { student, guest }

class AppSession {
  final AppUserRole role;
  final String? fullName;
  final String? email;

  const AppSession.student({
    String? fullName,
    String? firstName,
    this.email = 'student@belgiumcampus.ac.za',
  }) : assert(fullName != null || firstName != null),
       fullName = fullName ?? firstName,
       role = AppUserRole.student;

  const AppSession.guest()
    : role = AppUserRole.guest,
      fullName = null,
      email = null;

  bool get isStudent => role == AppUserRole.student;

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

  String get roleLabel => isStudent ? 'Student' : 'Guest';

  String get displayEmail {
    final value = email?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'No campus email';
  }
}
