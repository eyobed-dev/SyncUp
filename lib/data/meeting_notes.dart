import '../models/meeting.dart';
import 'past_session_note_templates.dart';

class PastMeetingNote {
  final DateTime when;
  final List<String> discussions;
  final List<String> todos;
  final String? notes;

  const PastMeetingNote({
    required this.when,
    required this.discussions,
    required this.todos,
    this.notes,
  });
}

/// Label built from the booking’s course fields on this [Meeting] row
/// ([Meeting.discipline], [Meeting.topic]) — topic may be Mentoring, Consultation, etc.
String? bookingCourseLabel(Meeting m) {
  final d = m.discipline?.trim();
  final t = m.topic?.trim();
  final hasD = d != null && d.isNotEmpty;
  final hasT = t != null && t.isNotEmpty;
  if (!hasD && !hasT) return null;
  if (hasD && hasT) return '$d — $t';
  if (hasD) return d;
  if (hasT) return t;
  return null;
}

/// Prior session history for this booking’s discipline/topic (templated notes).
/// Copy is merged from [PastSessionNoteTemplates] (loaded from JSON assets); whether any
/// history appears uses a stable hash of [Meeting.id] so the list stays varied.
List<PastMeetingNote> getPastMeetingNotes(Meeting m) {
  final course = bookingCourseLabel(m);
  if (course == null) return const [];

  final h = m.id.hashCode.abs();
  final bucket = h % 7;
  if (bucket == 0) return const [];

  final now = DateTime.now();
  final tpl = PastSessionNoteTemplates.instance;

  PastMeetingNote recent() {
    final daysAgo = 5 + (h % 12);
    final mergedNote = tpl.mergeNotesRecent(course).trim();
    return PastMeetingNote(
      when: now.subtract(Duration(days: daysAgo)),
      discussions: tpl.mergeDiscussionsRecent(course),
      todos: tpl.mergeTodosRecent(course),
      notes: (h % 2 == 0 && mergedNote.isNotEmpty) ? mergedNote : null,
    );
  }

  PastMeetingNote older() {
    final daysAgo = 18 + (h % 20);
    return PastMeetingNote(
      when: now.subtract(Duration(days: daysAgo)),
      discussions: tpl.mergeDiscussionsOlder(course),
      todos: tpl.mergeTodosOlder(course),
      notes: null,
    );
  }

  final List<PastMeetingNote> out;
  if (bucket <= 3) {
    out = [recent()];
  } else {
    out = [recent(), older()];
  }
  out.sort((a, b) => b.when.compareTo(a.when));
  return out;
}
