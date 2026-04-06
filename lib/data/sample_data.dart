import '../models/meeting.dart';
import '../utils/week_calendar.dart';

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

/// Returns the current meeting using the default sample list for [weekStart].
Meeting? getCurrentMeeting(DateTime weekStart) {
  return getCurrentMeetingFromList(getSampleMeetings(weekStart));
}

/// Sample meetings for demonstration – BUT University and Brno Dance School.
/// Students: MIT-EN (Masters), BSc (Bachelors). IT subjects: Compiler Construction, Formal Languages, etc.
/// Dance: Training Session. Locations: various rooms at FIT/BUT and Brno Dance School.
List<Meeting> getSampleMeetings(DateTime weekStart) {
  final weekSunday = startOfWeekSunday(
    DateTime(weekStart.year, weekStart.month, weekStart.day),
  );
  /// Monday is still the anchor for legacy offsets (Mon = +1 day from week Sunday).
  final monday = weekSunday.add(const Duration(days: 1));

  return [
    // Monday – BUT University IT
    Meeting(
      id: '1',
      participantName: 'Martin Novák',
      startTime: monday.add(const Duration(hours: 8)),
      durationMinutes: 30,
      discipline: 'MIT-EN',
      topic: 'Consultation – Compiler Construction',
      location: 'Room B109',
    ),
    Meeting(
      id: '2',
      participantName: 'Kateřina Svobodová',
      startTime: monday.add(const Duration(hours: 8, minutes: 45)),
      durationMinutes: 15,
      discipline: 'BSc',
      topic: 'Mentoring',
      location: 'Office 204',
    ),
    Meeting(
      id: '3',
      participantName: 'Jakub Horák',
      startTime: monday.add(const Duration(hours: 9, minutes: 30)),
      durationMinutes: 45,
      discipline: 'MIT-EN',
      topic: 'Consultation – Formal Languages',
      location: 'Lab B322',
    ),
    // Tuesday
    Meeting(
      id: '4',
      participantName: 'Anna Dvořáková',
      startTime: monday.add(const Duration(days: 1, hours: 8, minutes: 15)),
      durationMinutes: 45,
      discipline: 'BSc',
      topic: 'Consultation – Compiler Construction',
      location: 'Room B109',
    ),
    Meeting(
      id: '5',
      participantName: 'Tomáš Procházka',
      startTime: monday.add(const Duration(days: 1, hours: 9, minutes: 15)),
      durationMinutes: 30,
      discipline: 'MIT-EN',
      topic: 'Mentoring',
      location: 'Office 204',
    ),
    Meeting(
      id: 'tue1',
      participantName: 'Lucie Králová',
      startTime: monday.add(const Duration(days: 1, hours: 10, minutes: 30)),
      durationMinutes: 45,
      discipline: 'BSc',
      topic: 'Consultation – Formal Languages',
      location: 'Room B109',
    ),
    Meeting(
      id: 'tue2',
      participantName: 'Ondřej Marek',
      startTime: monday.add(const Duration(days: 1, hours: 11, minutes: 30)),
      durationMinutes: 30,
      discipline: 'MIT-EN',
      topic: 'Consultation – Compiler Construction',
      location: 'Lab B322',
    ),
    Meeting(
      id: 'tue2b',
      participantName: 'Tereza Nováková',
      startTime: monday.add(const Duration(days: 1, hours: 13)),
      durationMinutes: 90,
      discipline: 'BSc',
      topic: 'Training Session',
      location: 'Studio A, Brno Dance School',
    ),
    Meeting(
      id: 'tue3',
      participantName: 'Filip Černý',
      startTime: monday.add(const Duration(days: 1, hours: 14)),
      durationMinutes: 60,
      discipline: 'MIT-EN',
      topic: 'Consultation – Software Engineering',
      location: 'Room C101',
    ),
    Meeting(
      id: 'tue4',
      participantName: 'Barbora Malá',
      startTime: monday.add(const Duration(days: 1, hours: 15, minutes: 15)),
      durationMinutes: 45,
      discipline: 'BSc',
      topic: 'Mentoring',
      location: 'Office 312',
    ),
    Meeting(
      id: 'tue5',
      participantName: 'David Veselý',
      startTime: monday.add(const Duration(days: 1, hours: 16, minutes: 30)),
      durationMinutes: 30,
      discipline: 'MIT-EN',
      topic: 'Consultation – Algorithms',
      location: 'Room A215',
    ),
    // Wednesday
    Meeting(
      id: '6',
      participantName: 'Petra Holubová',
      startTime: monday.add(const Duration(days: 2, hours: 8)),
      durationMinutes: 60,
      discipline: 'BSc',
      topic: 'Consultation – Compiler Construction',
      location: 'Room B109',
    ),
    Meeting(
      id: '7',
      participantName: 'Jan Pokorný',
      startTime: monday.add(const Duration(days: 2, hours: 10)),
      durationMinutes: 15,
      discipline: 'MIT-EN',
      topic: 'Mentoring',
      location: 'Office 204',
    ),
    Meeting(
      id: 'w9',
      participantName: 'Štěpán Dvořák',
      startTime: monday.add(const Duration(days: 2, hours: 12)),
      durationMinutes: 30,
      discipline: 'MIT-EN',
      topic: 'Consultation – Software Engineering',
      location: 'Room B109',
    ),
    // Wednesday 15:30–17:30 – IT students
    Meeting(
      id: 'w1',
      participantName: 'Michaela Beránková',
      startTime: monday.add(const Duration(days: 2, hours: 15, minutes: 30)),
      durationMinutes: 15,
      discipline: 'BSc',
      topic: 'Consultation – Compiler Construction',
      location: 'Room B109',
    ),
    Meeting(
      id: 'w2',
      participantName: 'Adam Vávra',
      startTime: monday.add(const Duration(days: 2, hours: 15, minutes: 45)),
      durationMinutes: 15,
      discipline: 'MIT-EN',
      topic: 'Mentoring',
      location: 'Office 204',
    ),
    Meeting(
      id: 'w3',
      participantName: 'Eva Sedláčková',
      startTime: monday.add(const Duration(days: 2, hours: 16)),
      durationMinutes: 15,
      discipline: 'BSc',
      topic: 'Consultation – Formal Languages',
      location: 'Lab B322',
    ),
    Meeting(
      id: 'w4',
      participantName: 'Matěj Kovář',
      startTime: monday.add(const Duration(days: 2, hours: 16, minutes: 15)),
      durationMinutes: 15,
      discipline: 'MIT-EN',
      topic: 'Consultation – Data Structures',
      location: 'Room A215',
    ),
    Meeting(
      id: 'w5',
      participantName: 'Nikola Urbanová',
      startTime: monday.add(const Duration(days: 2, hours: 16, minutes: 30)),
      durationMinutes: 15,
      discipline: 'BSc',
      topic: 'Mentoring',
      location: 'Office 312',
    ),
    Meeting(
      id: 'w6',
      participantName: 'Vojtěch Hájek',
      startTime: monday.add(const Duration(days: 2, hours: 16, minutes: 45)),
      durationMinutes: 15,
      discipline: 'MIT-EN',
      topic: 'Consultation – Compiler Construction',
      location: 'Room B109',
    ),
    Meeting(
      id: 'w7',
      participantName: 'Karolína Bláhová',
      startTime: monday.add(const Duration(days: 2, hours: 17)),
      durationMinutes: 15,
      discipline: 'BSc',
      topic: 'Consultation – Database Systems',
      location: 'Lab C205',
    ),
    Meeting(
      id: 'w8',
      participantName: 'Daniel Soukup',
      startTime: monday.add(const Duration(days: 2, hours: 17, minutes: 15)),
      durationMinutes: 15,
      discipline: 'MIT-EN',
      topic: 'Mentoring',
      location: 'Office 405',
    ),
    // Thursday
    Meeting(
      id: '8',
      participantName: 'Kristýna Marková',
      startTime: monday.add(const Duration(days: 3, hours: 8)),
      durationMinutes: 30,
      discipline: 'BSc',
      topic: 'Consultation – Formal Languages',
      location: 'Room B109',
    ),
    Meeting(
      id: '9',
      participantName: 'Lukáš Pospíšil',
      startTime: monday.add(const Duration(days: 3, hours: 8, minutes: 30)),
      durationMinutes: 45,
      discipline: 'MIT-EN',
      topic: 'Consultation – Compiler Construction',
      location: 'Lab B322',
    ),
    // Thursday 10:30–12:00
    Meeting(
      id: 'th1',
      participantName: 'Ondřej Vlach',
      startTime: monday.add(const Duration(days: 3, hours: 10, minutes: 30)),
      durationMinutes: 30,
      discipline: 'BSc',
      topic: 'Consultation – Formal Languages',
      location: 'Room B109',
    ),
    Meeting(
      id: 'th2',
      participantName: 'Tereza Burešová',
      startTime: monday.add(const Duration(days: 3, hours: 11)),
      durationMinutes: 30,
      discipline: 'MIT-EN',
      topic: 'Mentoring',
      location: 'Office 204',
    ),
    Meeting(
      id: 'th3',
      participantName: 'Filip Kopecký',
      startTime: monday.add(const Duration(days: 3, hours: 11, minutes: 30)),
      durationMinutes: 30,
      discipline: 'BSc',
      topic: 'Consultation – Compiler Construction',
      location: 'Lab B322',
    ),
    // Thursday 15:30–16:15 (3 slots; 8 students total this day)
    Meeting(
      id: 't1',
      participantName: 'Simona Tichá',
      startTime: monday.add(const Duration(days: 3, hours: 15, minutes: 30)),
      durationMinutes: 15,
      discipline: 'BSc',
      topic: 'Mentoring',
      location: 'Office 204',
    ),
    Meeting(
      id: 't2',
      participantName: 'Radek Štěpánek',
      startTime: monday.add(const Duration(days: 3, hours: 15, minutes: 45)),
      durationMinutes: 15,
      discipline: 'MIT-EN',
      topic: 'Consultation – Algorithms',
      location: 'Room A215',
    ),
    Meeting(
      id: 't3',
      participantName: 'Veronika Kolářová',
      startTime: monday.add(const Duration(days: 3, hours: 16)),
      durationMinutes: 15,
      discipline: 'BSc',
      topic: 'Consultation – Compiler Construction',
      location: 'Room B109',
    ),
    // Friday
    Meeting(
      id: '10',
      participantName: 'Jana Novotná',
      startTime: monday.add(const Duration(days: 4, hours: 9)),
      durationMinutes: 30,
      discipline: 'BSc',
      topic: 'Consultation – Data Structures',
      location: 'Room A215',
    ),
    // Saturday – Brno Dance School
    Meeting(
      id: '11',
      participantName: 'Alžběta Horáková',
      startTime: monday.add(const Duration(days: 5, hours: 10)),
      durationMinutes: 60,
      discipline: null,
      topic: 'Training Session',
      location: 'Studio A, Brno Dance School',
    ),
    // Saturday (afternoon; week grid is Sun–Sat so former Sunday slot sits on Sat)
    Meeting(
      id: '12',
      participantName: 'Ondřej Kříž',
      startTime: monday.add(const Duration(days: 5, hours: 14)),
      durationMinutes: 45,
      discipline: 'MIT-EN',
      topic: 'Consultation – Compiler Construction',
      location: 'Zoom',
    ),
  ];
}
