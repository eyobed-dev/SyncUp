/// An available time slot that a user can book (e.g. Mentoring, Consultation).
class AvailabilitySlot {
  final String id;
  final DateTime startTime;
  final int durationMinutes;
  final String title; // e.g. "Mentoring", "Consultation Academic"
  final String? location;

  const AvailabilitySlot({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
    required this.title,
    this.location,
  });

  DateTime get endTime =>
      startTime.add(Duration(minutes: durationMinutes));
}
