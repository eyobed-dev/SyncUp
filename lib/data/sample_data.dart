/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Static datasets or mock data providers.
 */

import '../models/meeting.dart';
import 'live_backend_cache.dart';

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

/// Returns the current meeting from backend-synced weekly [meetings] for [weekStart].
Meeting? getCurrentMeeting(DateTime weekStart) {
  return getCurrentMeetingFromList(getMeetingsForWeek(weekStart));
}

/// Recurring weekly meetings for [weekStart] from backend cache.
List<Meeting> getMeetingsForWeek(DateTime weekStart) {
  return LiveBackendCache.instance.meetingsForWeek(weekStart) ?? const [];
}

/// Prior [sessions] for the same student as [booking] from backend cache.
/// Newest first.
List<Meeting> priorSessionsForBooking(Meeting booking) {
  return LiveBackendCache.instance.priorSessionsForBooking(booking) ?? const [];
}

Future<void> syncMeetingsForWeek(
  DateTime weekStart, {
  String ownerId = 'p1',
  String? participantName,
  String? participantUserId,
}) async {
  await LiveBackendCache.instance.syncMeetings(
    weekStart,
    ownerId: ownerId,
    participantName: participantName,
    participantUserId: participantUserId,
  );
}

Future<void> syncPriorSessionsForBooking(Meeting booking) async {
  await LiveBackendCache.instance.syncPriorSessions(booking);
}
