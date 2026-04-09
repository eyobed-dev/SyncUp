/// Represents a meeting/session between teacher-student or peer-to-peer.
/// Display format: Name - Discipline - Topic (e.g. John Blast - MIT-EN - Academic Consultation)
class Meeting {
  final String id;
  final String participantName;
  final String? photoUrl; // Placeholder - null uses default avatar
  final DateTime startTime;
  final int durationMinutes;
  /// Discipline/course code (e.g. MIT-EN, CS-101)
  final String? discipline;
  /// Topic or discussion subject (e.g. Academic Consultation)
  final String? topic;
  /// Location (e.g. Room 101, Zoom, Building A)
  final String? location;

  const Meeting({
    required this.id,
    required this.participantName,
    this.photoUrl,
    required this.startTime,
    required this.durationMinutes,
    this.discipline,
    this.topic,
    this.location,
  });

  /// App-wide room used for meetings.
  String get room => 'LL4';

  String get roomLabel => 'Room $room';

  /// Legacy alias for topic
  String? get subject => topic;

  DateTime get endTime =>
      startTime.add(Duration(minutes: durationMinutes));

  /// Full display string: "Name - Discipline - Topic"
  String get displayLabel {
    final parts = <String>[participantName];
    if (discipline != null && discipline!.isNotEmpty) parts.add(discipline!);
    if (topic != null && topic!.isNotEmpty) parts.add(topic!);
    return parts.join(' – ');
  }
}
