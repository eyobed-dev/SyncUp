/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Defines data models and entities for availability_slot.
 */

/// An available time slot that a user can book (e.g. Consultation, Mentoring).
class AvailabilitySlot {
  final String id;
  final DateTime startTime;
  final int durationMinutes;
  final String title; // e.g. "Consultation – …", "Mentoring"
  final String? location;
  final String? meetingLink;

  const AvailabilitySlot({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
    required this.title,
    this.location,
    this.meetingLink,
  });

  DateTime get endTime =>
      startTime.add(Duration(minutes: durationMinutes));
}
