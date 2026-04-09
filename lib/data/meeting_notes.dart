import '../models/meeting.dart';

class LastMeetingInfo {
  final List<String> discussions;
  final List<String> todos;
  final String? notes;

  const LastMeetingInfo({
    required this.discussions,
    required this.todos,
    this.notes,
  });
}

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

/// Demo-only: some students have prior meeting history, some don't.
List<PastMeetingNote> getPastMeetingNotes(Meeting m) {
  final key = m.participantName.trim();
  if (key.isEmpty) return const [];

  final now = DateTime.now();
  final data = <String, List<PastMeetingNote>>{
    'Martin Novák': [
      PastMeetingNote(
        when: now.subtract(const Duration(days: 14)),
        discussions: const [
          'Reviewed CFG transformations for the assignment',
          'Clarified grading criteria and common mistakes',
        ],
        todos: const [
          'Finish LL(1) parsing exercises',
          'Send draft solution for quick review',
        ],
        notes: 'Student is progressing well; needs more practice with FIRST/FOLLOW sets.',
      ),
      PastMeetingNote(
        when: now.subtract(const Duration(days: 28)),
        discussions: const [
          'Walked through FIRST/FOLLOW examples',
          'Talked about typical pitfalls in grammar design',
        ],
        todos: const [
          'Rewrite grammar to remove left recursion',
          'Bring 2 questions about ambiguity',
        ],
        notes: null,
      ),
    ],
    'Kateřina Svobodová': [
      PastMeetingNote(
        when: now.subtract(const Duration(days: 7)),
        discussions: const [
          'Discussed study plan for finals',
          'Identified weak spots in recursion and complexity',
        ],
        todos: const [
          'Do 3 practice problems on recursion',
          'Bring questions next session',
        ],
        notes: null,
      ),
    ],
    // No notes for many students on purpose (demo).
    'Filip Černý': [
      PastMeetingNote(
        when: now.subtract(const Duration(days: 10)),
        discussions: const [
          'Project status update and architecture review',
          'Agreed on refactor steps for service boundaries',
        ],
        todos: const [
          'Refactor module boundaries',
          'Add 2 integration tests for critical path',
        ],
        notes: 'Follow-up: check on test flakiness next week.',
      ),
      PastMeetingNote(
        when: now.subtract(const Duration(days: 24)),
        discussions: const [
          'Reviewed sprint goals and scope',
          'Clarified deliverables for the next milestone',
        ],
        todos: const [
          'Prepare a short demo plan',
          'List open questions for review',
        ],
        notes: null,
      ),
    ],
  };

  final list = data[key] ?? const [];
  final sorted = [...list]..sort((a, b) => b.when.compareTo(a.when));
  return sorted;
}

