enum AppUserRole { student, guest }

class AppSession {
  final AppUserRole role;
  final String? firstName;

  const AppSession.student({required this.firstName})
    : role = AppUserRole.student;

  const AppSession.guest() : role = AppUserRole.guest, firstName = null;

  bool get isStudent => role == AppUserRole.student;

  bool get isGuest => role == AppUserRole.guest;
}
