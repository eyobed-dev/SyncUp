// ignore_for_file: avoid_print
/// Generates assets/data/backend_seed.json (UTF-8) from the former in-code seed.
/// Run: dart run tool/generate_backend_seed_json.dart
import 'dart:convert';
import 'dart:io';

/// Prior-session UI copy merged with `{course}`; same shape as `sessionNoteTemplates` in the JSON root.
const Map<String, Object?> kSessionNoteTemplates = {
  '_comment':
      'Placeholders: {course} is replaced with discipline/topic from the booking. Topic may be Mentoring, Consultation, etc.',
  'placeholder': '{course}',
  'recent': {
    'discussions': [
      'Check-in on {course} — reviewed progress and blockers',
      'Aligned next steps from the last session on {course}',
    ],
    'todos': [
      'Apply agreed actions before the next scheduled slot',
      'Bring questions tied to {course} for follow-up',
    ],
    'notes': 'Brief note associated with {course}.',
  },
  'older': {
    'discussions': [
      'Planning session for {course} — clarified goals for the term',
      'Reviewed materials the student selected for this focus area',
    ],
    'todos': [
      'Confirm readings or tasks for {course} before next session',
    ],
  },
};

void main() {
  const owners = [
    {
      'id': 'p1',
      'name': 'Prof. Alexander Meduna',
      'role': 'Professor',
      'department': 'FIT, BUT',
      'email': 'meduna@fit.vutbr.cz',
    },
    {
      'id': 'p2',
      'name': 'Dr. Jan Novák',
      'role': 'Associate Professor',
      'department': 'FIT, BUT',
      'email': 'novak@fit.vutbr.cz',
    },
    {
      'id': 'p3',
      'name': 'Prof. Marie Svobodová',
      'role': 'Professor',
      'department': 'FIT, BUT',
      'email': 'svobodova@fit.vutbr.cz',
    },
    {
      'id': 'd1',
      'name': 'Eva Nováková',
      'role': 'Dance Instructor',
      'department': 'Brno Dance School',
      'email': 'novakova@brnodance.cz',
    },
    {
      'id': 'd2',
      'name': 'Petr Horák',
      'role': 'Dance Instructor',
      'department': 'Brno Dance School',
      'email': 'horak@brnodance.cz',
    },
  ];

  final meetings = <Map<String, Object?>>[
    _m('1', 'Martin Novák', 0, 8, 0, 30, 'MIT-EN', 'Consultation – Compiler Construction', 'Room B109'),
    _m('2', 'Kateřina Svobodová', 0, 8, 45, 15, 'BSc', 'Mentoring', 'Office 204'),
    _m('3', 'Jakub Horák', 0, 9, 30, 45, 'MIT-EN', 'Consultation – Formal Languages', 'Lab B322'),
    _m('4', 'Anna Dvořáková', 1, 8, 15, 45, 'BSc', 'Consultation – Compiler Construction', 'Room B109'),
    _m('5', 'Tomáš Procházka', 1, 9, 15, 30, 'MIT-EN', 'Mentoring', 'Office 204'),
    _m('tue1', 'Lucie Králová', 1, 10, 30, 45, 'BSc', 'Consultation – Formal Languages', 'Room B109'),
    _m('tue2', 'Ondřej Marek', 1, 11, 30, 30, 'MIT-EN', 'Consultation – Compiler Construction', 'Lab B322'),
    _m('tue2b', 'Tereza Nováková', 1, 13, 0, 90, 'BSc', 'Training Session', 'Studio A, Brno Dance School'),
    _m('tue3', 'Filip Černý', 1, 14, 0, 60, 'MIT-EN', 'Consultation – Software Engineering', 'Room C101'),
    _m('tue4', 'Barbora Malá', 1, 15, 15, 45, 'BSc', 'Mentoring', 'Office 312'),
    _m('tue5', 'David Veselý', 1, 16, 30, 30, 'MIT-EN', 'Consultation – Algorithms', 'Room A215'),
    _m('6', 'Petra Holubová', 2, 8, 0, 60, 'BSc', 'Consultation – Compiler Construction', 'Room B109'),
    _m('7', 'Jan Pokorný', 2, 10, 0, 15, 'MIT-EN', 'Mentoring', 'Office 204'),
    _m('w9', 'Štěpán Dvořák', 2, 12, 0, 30, 'MIT-EN', 'Consultation – Software Engineering', 'Room B109'),
    _m('w1', 'Michaela Beránková', 2, 15, 30, 15, 'BSc', 'Consultation – Compiler Construction', 'Room B109'),
    _m('w2', 'Adam Vávra', 2, 15, 45, 15, 'MIT-EN', 'Mentoring', 'Office 204'),
    _m('w3', 'Eva Sedláčková', 2, 16, 0, 15, 'BSc', 'Consultation – Formal Languages', 'Lab B322'),
    _m('w4', 'Matěj Kovář', 2, 16, 15, 15, 'MIT-EN', 'Consultation – Data Structures', 'Room A215'),
    _m('w5', 'Nikola Urbanová', 2, 16, 30, 15, 'BSc', 'Mentoring', 'Office 312'),
    _m('w6', 'Vojtěch Hájek', 2, 16, 45, 15, 'MIT-EN', 'Consultation – Compiler Construction', 'Room B109'),
    _m('w7', 'Karolína Bláhová', 2, 17, 0, 15, 'BSc', 'Consultation – Database Systems', 'Lab C205'),
    _m('w8', 'Daniel Soukup', 2, 17, 15, 15, 'MIT-EN', 'Mentoring', 'Office 405'),
    _m('8', 'Kristýna Marková', 3, 8, 0, 30, 'BSc', 'Consultation – Formal Languages', 'Room B109'),
    _m('9', 'Lukáš Pospíšil', 3, 8, 30, 45, 'MIT-EN', 'Consultation – Compiler Construction', 'Lab B322'),
    _m('t2', 'Radek Štěpánek', 3, 15, 45, 15, 'MIT-EN', 'Consultation – Algorithms', 'Room A215'),
    _m('t3', 'Veronika Kolářová', 4, 16, 0, 15, 'BSc', 'Consultation – Compiler Construction', 'Room B109'),
    _m('10', 'Jana Novotná', 4, 9, 0, 30, 'BSc', 'Consultation – Data Structures', 'Room A215'),
    _m('f2', 'Veronika Kolářová', 4, 11, 0, 30, 'BSc', 'Consultation – Academic Planning', 'Office 204'),
    _m('f3', 'Filip Kopecký', 4, 14, 30, 45, 'BSc', 'Consultation – Project Review', 'Room B109'),
    _m('11', 'Alžběta Horáková', 5, 10, 0, 60, null, 'Training Session', 'Studio A, Brno Dance School'),
    _m('12', 'Ondřej Kříž', 5, 14, 0, 45, 'MIT-EN', 'Consultation – Compiler Construction', 'Zoom'),
  ];

  final seen = <String, String>{};
  var i = 0;
  for (final m in meetings) {
    final name = m['participantName'] as String;
    seen.putIfAbsent(name, () => 'stu-${++i}');
  }
  final students = seen.entries.map((e) => {'id': e.value, 'displayName': e.key}).toList();

  for (final m in meetings) {
    m['studentId'] = seen[m['participantName'] as String]!;
  }

  for (final m in meetings) {
    m['topic'] = 'Mentoring';
  }

  // Almost half of students have past sessions; of those, half have exactly one,
  // the other half have 2–5 sessions with minutes + deliberations.
  final nStudents = students.length;
  final withHistory = (nStudents + 1) ~/ 2;
  final singleSessionCount = withHistory ~/ 2;
  final sessions = <Map<String, Object?>>[];

  for (var gi = 0; gi < withHistory; gi++) {
    final st = students[gi] as Map<String, Object?>;
    final sid = st['id']! as String;
    final row = meetings.firstWhere((m) => m['studentId'] == sid);
    final name = row['participantName']! as String;
    final topic = row['topic']! as String;

    if (gi < singleSessionCount) {
      final start = _pastSessionStartSingle(gi);
      sessions.add(_sessionJson(
        id: 'session-$sid-past-1',
        row: row,
        sid: sid,
        start: start,
        minutes: 'Brief prior session with $name: check-in and quick plan for $topic.',
        deliberations: null,
      ));
    } else {
      final multiIndex = gi - singleSessionCount;
      final count = 2 + (multiIndex % 4);
      final newest = DateTime(2026, 2, 26, 14, 0).subtract(Duration(days: gi * 2));
      for (var k = 0; k < count; k++) {
        final start = newest.subtract(Duration(days: k * 11, hours: k % 5, minutes: (k * 7) % 60));
        sessions.add(_sessionJson(
          id: 'session-$sid-past-${k + 1}',
          row: row,
          sid: sid,
          start: start,
          minutes: _seedMinutes(name, topic, k),
          deliberations: _seedDeliberations(name, topic, k),
        ));
      }
    }
  }

  final availability = <String, List<Map<String, Object?>>>{
    'p1': [
      _s('p1-m1-1', 0, 8, 0, 15, 'Mentoring', 'Office 204, Božetěchova 2'),
      _s('p1-m1-2', 0, 8, 30, 30, 'Consultation – Compiler Construction', 'Room B109'),
      _s('p1-t1-1', 1, 9, 0, 15, 'Mentoring', 'Office 204'),
      _s('p1-t1-2', 1, 9, 30, 30, 'Consultation – Formal Languages', 'Room B109'),
      _s('p1-t1-3', 1, 10, 15, 15, 'Mentoring', 'Office 204'),
      _s('p1-w1-1', 2, 8, 0, 30, 'Consultation – Compiler Construction', 'Room B109'),
      _s('p1-w1-2', 2, 8, 30, 15, 'Mentoring', 'Office 204'),
      _s('p1-w1-3', 2, 8, 45, 15, 'Mentoring', 'Office 204'),
      _s('p1-w1-4', 2, 9, 15, 30, 'Consultation – Formal Languages', 'Lab B322'),
      _s('p1-w1-5', 2, 10, 0, 15, 'Mentoring', 'Zoom'),
      _s('p1-th1-1', 3, 11, 0, 30, 'Mentoring', 'Office 204'),
      _s('p1-th1-2', 3, 13, 15, 15, 'Mentoring', 'Zoom'),
      _s('p1-th1-3', 3, 9, 0, 15, 'Mentoring', 'Office 204'),
      _s('p1-th1-4', 3, 15, 0, 30, 'Mentoring', 'Room B109'),
      _s('p1-th1-5', 3, 8, 0, 15, 'Mentoring', 'Office 204'),
      _s('p1-th1-6', 3, 10, 0, 30, 'Mentoring', 'Room B109'),
      _s('p1-th1-7', 3, 12, 0, 15, 'Mentoring', 'Zoom'),
      _s('p1-th1-8', 3, 16, 0, 15, 'Mentoring', 'Office 204'),
      _s('p1-f1-1', 4, 9, 30, 30, 'Mentoring', 'Room B109'),
      _s('p1-f1-2', 4, 15, 0, 15, 'Mentoring', 'Office 204'),
      _s('p1-f1-3', 4, 8, 0, 15, 'Mentoring', 'Office 204'),
      _s('p1-f1-4', 4, 10, 0, 30, 'Mentoring', 'Room B109'),
      _s('p1-f1-5', 4, 12, 15, 15, 'Mentoring', 'Zoom'),
      _s('p1-f1-6', 4, 13, 0, 30, 'Mentoring', 'Office 204'),
      _s('p1-f1-7', 4, 16, 30, 15, 'Mentoring', 'Office 204'),
    ],
    'p2': [
      _s('p2-m1-1', 0, 10, 0, 30, 'Consultation – Algorithms', 'Room A215'),
      _s('p2-m1-2', 0, 10, 45, 15, 'Mentoring', 'Office 312'),
      _s('p2-w1-1', 2, 14, 0, 30, 'Consultation – Data Structures', 'Room A215'),
      _s('p2-w1-2', 2, 14, 45, 15, 'Mentoring', 'Office 312'),
    ],
    'p3': [
      _s('p3-t1-1', 1, 13, 0, 30, 'Consultation – Software Engineering', 'Room C101'),
      _s('p3-t1-2', 1, 13, 45, 15, 'Mentoring', 'Office 405'),
      _s('p3-th1-1', 3, 9, 0, 30, 'Consultation – Database Systems', 'Lab C205'),
    ],
    'd1': [
      _s('d1-m1-1', 0, 16, 0, 60, 'Training Session', 'Studio A'),
      _s('d1-w1-1', 2, 17, 0, 60, 'Training Session', 'Studio A'),
      _s('d1-f1-1', 4, 15, 0, 60, 'Training Session', 'Main Hall'),
    ],
    'd2': [
      _s('d2-t1-1', 1, 18, 0, 60, 'Training Session', 'Studio B'),
      _s('d2-th1-1', 3, 17, 0, 60, 'Training Session', 'Studio B'),
    ],
  };

  final out = {
    'schemaVersion': 1,
    'description':
        'Application data: students, schedule owners, meetings, sessions, availability, and session note templates.',
    'sessionNoteTemplates': kSessionNoteTemplates,
    'students': students,
    'scheduleOwners': owners,
    'meetings': meetings,
    'sessions': sessions,
    'availabilityByOwnerId': availability,
  };

  final text = const JsonEncoder.withIndent('  ').convert(out);
  File('assets/data/backend_seed.json').writeAsStringSync(text, encoding: utf8);
  print('Wrote assets/data/backend_seed.json (${text.length} chars)');
}

Map<String, Object?> _m(
  String id,
  String participantName,
  int daysAfterMonday,
  int startHour,
  int startMinute,
  int durationMinutes,
  String? discipline,
  String topic,
  String location,
) {
  return {
    'id': id,
    'participantName': participantName,
    'daysAfterMonday': daysAfterMonday,
    'startHour': startHour,
    'startMinute': startMinute,
    'durationMinutes': durationMinutes,
    'discipline': discipline,
    'topic': topic,
    'location': location,
  };
}

Map<String, Object?> _s(
  String id,
  int daysAfterMonday,
  int startHour,
  int startMinute,
  int durationMinutes,
  String title,
  String location,
) {
  return {
    'id': id,
    'daysAfterMonday': daysAfterMonday,
    'startHour': startHour,
    'startMinute': startMinute,
    'durationMinutes': durationMinutes,
    'title': title,
    'location': location,
  };
}

DateTime _pastSessionStartSingle(int gi) => DateTime(2026, 1, 8, 10, 30).add(
      Duration(days: gi * 5, hours: gi % 5, minutes: (gi * 11) % 60),
    );

Map<String, Object?> _sessionJson({
  required String id,
  required Map<String, Object?> row,
  required String sid,
  required DateTime start,
  String? minutes,
  String? deliberations,
}) {
  final o = <String, Object?>{
    'id': id,
    'studentId': sid,
    'participantName': row['participantName']!,
    'startTime': start.toIso8601String(),
    'durationMinutes': row['durationMinutes']!,
    'discipline': row['discipline'],
    'topic': row['topic']!,
    'location': row['location']!,
  };
  if (minutes != null) o['minutes'] = minutes;
  if (deliberations != null) o['deliberations'] = deliberations;
  return o;
}

String _seedMinutes(String name, String topic, int k) {
  final snippets = <String>[
    'Reviewed progress with $name on $topic. Walked through recent work and clarified expectations.',
    'Discussed blockers and next milestones for $topic. Agreed on readings and practice focus.',
    'Follow-up on action items from prior week. Student summarized understanding of key concepts.',
    'Office-style session: answered questions on $topic and outlined the path to the next checkpoint.',
    'Checked preparation for upcoming work in $topic; adjusted pace based on student feedback.',
  ];
  return snippets[k % snippets.length];
}

String _seedDeliberations(String name, String topic, int k) {
  final snippets = <String>[
    'Agreed to continue with the current plan; reconvene if new blockers appear before the next slot.',
    'Confirmed deadline alignment for $topic; student to send one-page summary by the agreed date.',
    'Decided to prioritize exercises A–C; optional stretch items deferred to the following week.',
    'Recorded consent to share brief status with the instructor of record if grades are affected.',
    'Set expectation that $name brings two concrete questions to the next session on $topic.',
  ];
  return snippets[k % snippets.length];
}
