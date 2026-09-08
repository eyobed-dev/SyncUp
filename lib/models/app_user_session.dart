/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Defines data models and entities for app_user_session.
 */

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
