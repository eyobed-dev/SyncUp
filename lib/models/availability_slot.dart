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
