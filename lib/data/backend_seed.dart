import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/availability_slot.dart';
import '../models/meeting.dart';
import '../models/schedule_owner.dart';
import '../utils/week_calendar.dart';

/// Row in [backend_seed.json] `students` — backend-style roster ([Meeting.studentId] links here).
class SeedStudent {
  const SeedStudent({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

/// Loads `assets/data/backend_seed.json`: students, schedule owners, recurring [meetings],
/// absolute-time [sessions], and availability. The `sessionNoteTemplates` section of the same
/// file is read separately by `PastSessionNoteTemplates.load`.
/// Recurring rows use times relative to **Monday 00:00** of the ISO week for [weekStart].
class BackendSeed {
  BackendSeed._({
    required this.students,
    required this.scheduleOwners,
    required List<_MeetingSeedRow> meetingRows,
    required List<Meeting> sessionMeetings,
    required Map<String, List<_SlotSeedRow>> availabilityRows,
  })  : _meetingRows = meetingRows,
        _sessionMeetings = sessionMeetings,
        _availabilityRows = availabilityRows;

  static BackendSeed? _instance;

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/backend_seed.json');
    _instance = BackendSeed._parse(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Must call [load] from `main()` after [WidgetsFlutterBinding.ensureInitialized].
  static BackendSeed get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('BackendSeed.load() must be awaited before accessing seed data.');
    }
    return i;
  }

  final List<SeedStudent> students;
  final List<ScheduleOwner> scheduleOwners;
  final List<_MeetingSeedRow> _meetingRows;
  final List<Meeting> _sessionMeetings;
  final Map<String, List<_SlotSeedRow>> _availabilityRows;

  /// Calendar sessions from JSON (`sessions`): concrete [startTime]s (past or future).
  /// The UI filters by user, date range, or `Meeting.endTime` vs "now" as needed.
  List<Meeting> get seedSessions => List.unmodifiable(_sessionMeetings);

  static BackendSeed _parse(Map<String, dynamic> json) {
    final students = (json['students'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return SeedStudent(
        id: m['id'] as String,
        displayName: m['displayName'] as String,
      );
    }).toList();

    final scheduleOwners = (json['scheduleOwners'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return ScheduleOwner(
        id: m['id'] as String,
        name: m['name'] as String,
        role: m['role'] as String?,
        department: m['department'] as String?,
        email: m['email'] as String?,
      );
    }).toList();

    final meetingsJson = json['meetings'] ?? json['sampleMeetings'];
    if (meetingsJson == null) {
      throw StateError('backend_seed.json must include a "meetings" array.');
    }
    final meetingRows = (meetingsJson as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return _MeetingSeedRow(
        id: m['id'] as String,
        participantName: m['participantName'] as String,
        studentId: m['studentId'] as String?,
        daysAfterMonday: m['daysAfterMonday'] as int,
        startHour: m['startHour'] as int,
        startMinute: m['startMinute'] as int,
        durationMinutes: m['durationMinutes'] as int,
        discipline: m['discipline'] as String?,
        topic: m['topic'] as String?,
        location: m['location'] as String?,
      );
    }).toList();

    final sessionsJson = json['sessions'] as List<dynamic>? ?? const [];
    final sessionMeetings = sessionsJson.map((e) {
      final m = e as Map<String, dynamic>;
      final start = DateTime.parse(m['startTime'] as String);
      return Meeting(
        id: m['id'] as String,
        participantName: m['participantName'] as String,
        studentId: m['studentId'] as String?,
        startTime: start,
        durationMinutes: m['durationMinutes'] as int,
        discipline: m['discipline'] as String?,
        topic: m['topic'] as String?,
        location: m['location'] as String?,
        minutes: m['minutes'] as String?,
        deliberations: m['deliberations'] as String?,
      );
    }).toList();

    final avRoot = json['availabilityByOwnerId'] as Map<String, dynamic>;
    final availabilityRows = <String, List<_SlotSeedRow>>{};
    for (final e in avRoot.entries) {
      availabilityRows[e.key] = (e.value as List<dynamic>).map((row) {
        final m = row as Map<String, dynamic>;
        return _SlotSeedRow(
          id: m['id'] as String,
          daysAfterMonday: m['daysAfterMonday'] as int,
          startHour: m['startHour'] as int,
          startMinute: m['startMinute'] as int,
          durationMinutes: m['durationMinutes'] as int,
          title: m['title'] as String,
          location: m['location'] as String?,
        );
      }).toList();
    }

    return BackendSeed._(
      students: students,
      scheduleOwners: scheduleOwners,
      meetingRows: meetingRows,
      sessionMeetings: sessionMeetings,
      availabilityRows: availabilityRows,
    );
  }

  static DateTime mondayMidnightForWeek(DateTime weekStart) {
    final weekSunday = startOfWeekSunday(DateTime(weekStart.year, weekStart.month, weekStart.day));
    return weekSunday.add(const Duration(days: 1));
  }

  /// Recurring weekly [Meeting]s for [weekStart] (from JSON `meetings`).
  List<Meeting> meetingsForWeek(DateTime weekStart) {
    final monday = mondayMidnightForWeek(weekStart);
    return _meetingRows.map((t) {
      return Meeting(
        id: t.id,
        participantName: t.participantName,
        studentId: t.studentId,
        startTime: monday.add(Duration(
          days: t.daysAfterMonday,
          hours: t.startHour,
          minutes: t.startMinute,
        )),
        durationMinutes: t.durationMinutes,
        discipline: t.discipline,
        topic: t.topic,
        location: t.location,
        minutes: null,
        deliberations: null,
      );
    }).toList();
  }

  List<AvailabilitySlot> availabilityForOwner(String ownerId, DateTime weekStart) {
    final rows = _availabilityRows[ownerId];
    if (rows == null || rows.isEmpty) return [];
    final monday = mondayMidnightForWeek(weekStart);
    return rows.map((t) {
      return AvailabilitySlot(
        id: t.id,
        startTime: monday.add(Duration(
          days: t.daysAfterMonday,
          hours: t.startHour,
          minutes: t.startMinute,
        )),
        durationMinutes: t.durationMinutes,
        title: t.title,
        location: t.location,
      );
    }).toList();
  }
}

class _MeetingSeedRow {
  const _MeetingSeedRow({
    required this.id,
    required this.participantName,
    this.studentId,
    required this.daysAfterMonday,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    this.discipline,
    this.topic,
    this.location,
  });

  final String id;
  final String participantName;
  final String? studentId;
  final int daysAfterMonday;
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final String? discipline;
  final String? topic;
  final String? location;
}

class _SlotSeedRow {
  const _SlotSeedRow({
    required this.id,
    required this.daysAfterMonday,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    required this.title,
    this.location,
  });

  final String id;
  final int daysAfterMonday;
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final String title;
  final String? location;
}

/// Backend-style student roster from JSON (`students` in [backend_seed.json]).
List<SeedStudent> getSeedStudents() => BackendSeed.instance.students;
