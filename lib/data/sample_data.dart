import '../models/meeting.dart';
import 'backend_seed.dart';

/// Returns the meeting that is currently ongoing or recently ended (within 1 min), if any.
/// When "Just ended" expires, returns null so the card disappears and the next meeting is shown.
Meeting? getCurrentMeetingFromList(List<Meeting> meetings) {
  final now = DateTime.now();
  for (final m in meetings) {
    if (!now.isBefore(m.startTime) && now.isBefore(m.endTime)) {
      return m;
    }
    // Include meetings that ended in the last 1 min so user can submit status
    if (now.isAfter(m.endTime) && now.difference(m.endTime).inMinutes <= 1) {
      return m;
    }
  }
  return null;
}

/// Returns the current meeting from seed recurring [meetings] for [weekStart].
Meeting? getCurrentMeeting(DateTime weekStart) {
  return getCurrentMeetingFromList(getMeetingsForWeek(weekStart));
}

/// Recurring weekly meetings for [weekStart] — from [assets/data/backend_seed.json] `meetings`.
List<Meeting> getMeetingsForWeek(DateTime weekStart) {
  return BackendSeed.instance.meetingsForWeek(weekStart);
}

/// Seed [sessions] that are already over, for the same student as [booking] (by [Meeting.studentId]
/// or name when ids are absent). Newest first.
List<Meeting> priorSessionsForBooking(Meeting booking) {
  final now = DateTime.now();
  bool matches(Meeting s) {
    final sid = booking.studentId;
    if (sid != null && sid.isNotEmpty) {
      return s.studentId == sid;
    }
    return s.participantName.trim() == booking.participantName.trim();
  }

  final out = BackendSeed.instance.seedSessions
      .where((s) => matches(s) && s.endTime.isBefore(now))
      .toList();
  out.sort((a, b) => b.startTime.compareTo(a.startTime));
  return out;
}
