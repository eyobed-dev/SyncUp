/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Defines data models and entities for schedule_owner.
 */

/// A person whose schedule can be viewed (professor, coach, mentor, etc.).
class ScheduleOwner {
  final String id;
  final String name;
  final String? role; // Professor, Team Coach, Mentor, etc.
  final String? department;
  final String? email;

  const ScheduleOwner({
    required this.id,
    required this.name,
    this.role,
    this.department,
    this.email,
  });

  String get displayLabel => role != null ? '$name – $role' : name;
}
