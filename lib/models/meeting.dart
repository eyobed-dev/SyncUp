/// Represents a meeting/session between teacher-student or peer-to-peer.
/// Display format: Name - Discipline - Topic (e.g. John Blast - MIT-EN - Academic Consultation)
class Meeting {
  final String id;
  final String participantName;

  /// Roster id when known (links recurring bookings to backend `sessions`).
  final String? studentId;
  final String? photoUrl; // Placeholder - null uses default avatar
  final DateTime startTime;
  final int durationMinutes;

  /// Discipline/course code (e.g. MIT-EN, CS-101)
  final String? discipline;

  /// Topic or discussion subject (e.g. Academic Consultation)
  final String? topic;

  /// Location (e.g. Room 101, Zoom, Building A)
  final String? location;

  /// Recorded minutes (e.g. from seed past [sessions]).
  final String? minutes;

  /// Decisions / deliberations text for past sessions when present.
  final String? deliberations;

  /// Status submitted for this meeting occurrence.
  /// Expected values: happened, late, postponed, cancelled.
  final String? meetingStatus;

  const Meeting({
    required this.id,
    required this.participantName,
    this.studentId,
    this.photoUrl,
    required this.startTime,
    required this.durationMinutes,
    this.discipline,
    this.topic,
    this.location,
    this.minutes,
    this.deliberations,
    this.meetingStatus,
  });

  Meeting copyWith({
    String? id,
    String? participantName,
    String? studentId,
    String? photoUrl,
    DateTime? startTime,
    int? durationMinutes,
    String? discipline,
    String? topic,
    String? location,
    String? minutes,
    String? deliberations,
    String? meetingStatus,
  }) {
    return Meeting(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      studentId: studentId ?? this.studentId,
      photoUrl: photoUrl ?? this.photoUrl,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      discipline: discipline ?? this.discipline,
      topic: topic ?? this.topic,
      location: location ?? this.location,
      minutes: minutes ?? this.minutes,
      deliberations: deliberations ?? this.deliberations,
      meetingStatus: meetingStatus ?? this.meetingStatus,
    );
  }

  /// App-wide room used for meetings.
  String get room => 'LL4';

  String get roomLabel => 'Room $room';

  /// Legacy alias for topic
  String? get subject => topic;

  /// True only for genuinely unbooked slots.
  /// A slot named "Open slot" but already linked to a student is treated as booked.
  bool get isOpenSlot {
    final isNamedOpenSlot = participantName.trim().toLowerCase() == 'open slot';
    final hasStudent = (studentId ?? '').trim().isNotEmpty;
    return isNamedOpenSlot && !hasStudent;
  }

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  /// Full display string: "Name - Discipline - Topic"
  String get displayLabel {
    final parts = <String>[participantName];
    if (discipline != null && discipline!.isNotEmpty) parts.add(discipline!);
    final normalizedTopic = topic?.trim();
    final isOpenTopic = normalizedTopic?.toLowerCase() == 'open slot';
    if (normalizedTopic != null && normalizedTopic.isNotEmpty && !isOpenTopic) {
      parts.add(normalizedTopic);
    }
    return parts.join(' – ');
  }

  /// List/grid title line; set [includeTopic] false when the list shares one topic via
  /// [uniformNonEmptyTopicIfAllSame].
  String listTitleLabel({bool includeTopic = true}) {
    final parts = <String>[participantName];
    if (discipline != null && discipline!.isNotEmpty) parts.add(discipline!);
    final normalizedTopic = topic?.trim();
    final isOpenTopic = normalizedTopic?.toLowerCase() == 'open slot';
    if (includeTopic &&
        normalizedTopic != null &&
        normalizedTopic.isNotEmpty &&
        !isOpenTopic) {
      parts.add(normalizedTopic);
    }
    return parts.join(' – ');
  }

  /// Returns the shared topic when **every** meeting has the same non-empty [topic]; otherwise `null`.
  static String? uniformNonEmptyTopicIfAllSame(Iterable<Meeting> meetings) {
    String? first;
    for (final m in meetings) {
      final t = m.topic?.trim();
      if (t == null || t.isEmpty) return null;
      if (first == null) {
        first = t;
      } else if (first != t) {
        return null;
      }
    }
    return first;
  }
}
