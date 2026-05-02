enum AppUserRole { owner, attendee }

class AppUserSession {
  const AppUserSession({
    required this.userId,
    required this.username,
    required this.role,
    required this.displayName,
    this.ownerId,
    this.discipline,
  });

  final String userId;
  final String username;
  final AppUserRole role;
  final String displayName;
  final String? ownerId;
  final String? discipline;
}
