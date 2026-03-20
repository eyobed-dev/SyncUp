import '../models/availability_slot.dart';

/// Returns available slots for a schedule owner in the given week.
/// BUT University (IT): Mentoring, Consultation for Compiler Construction, Formal Languages, etc.
/// Brno Dance School: Training Session.
List<AvailabilitySlot> getAvailabilityForOwner(String ownerId, DateTime weekStart) {
  final monday = DateTime(weekStart.year, weekStart.month, weekStart.day)
      .subtract(Duration(days: weekStart.weekday - 1));

  if (ownerId == 'p1') {
    // Prof. Alexander Meduna – Compiler Construction, Formal Languages
    return [
      AvailabilitySlot(
        id: 'p1-m1-1',
        startTime: monday.add(const Duration(hours: 8)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Office 204, Božetěchova 2',
      ),
      AvailabilitySlot(
        id: 'p1-m1-2',
        startTime: monday.add(const Duration(hours: 8, minutes: 30)),
        durationMinutes: 30,
        title: 'Consultation – Compiler Construction',
        location: 'Room B109',
      ),
      AvailabilitySlot(
        id: 'p1-t1-1',
        startTime: monday.add(const Duration(days: 1, hours: 9)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Office 204',
      ),
      AvailabilitySlot(
        id: 'p1-t1-2',
        startTime: monday.add(const Duration(days: 1, hours: 9, minutes: 30)),
        durationMinutes: 30,
        title: 'Consultation – Formal Languages',
        location: 'Room B109',
      ),
      AvailabilitySlot(
        id: 'p1-t1-3',
        startTime: monday.add(const Duration(days: 1, hours: 10, minutes: 15)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Office 204',
      ),
      AvailabilitySlot(
        id: 'p1-w1-1',
        startTime: monday.add(const Duration(days: 2, hours: 8)),
        durationMinutes: 30,
        title: 'Consultation – Compiler Construction',
        location: 'Room B109',
      ),
      AvailabilitySlot(
        id: 'p1-w1-2',
        startTime: monday.add(const Duration(days: 2, hours: 8, minutes: 30)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Office 204',
      ),
      AvailabilitySlot(
        id: 'p1-w1-3',
        startTime: monday.add(const Duration(days: 2, hours: 8, minutes: 45)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Office 204',
      ),
      AvailabilitySlot(
        id: 'p1-w1-4',
        startTime: monday.add(const Duration(days: 2, hours: 9, minutes: 15)),
        durationMinutes: 30,
        title: 'Consultation – Formal Languages',
        location: 'Lab B322',
      ),
      AvailabilitySlot(
        id: 'p1-w1-5',
        startTime: monday.add(const Duration(days: 2, hours: 10)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Zoom',
      ),
    ];
  }

  if (ownerId == 'p2') {
    // Dr. Jan Novák – Algorithms, Data Structures
    return [
      AvailabilitySlot(
        id: 'p2-m1-1',
        startTime: monday.add(const Duration(hours: 10)),
        durationMinutes: 30,
        title: 'Consultation – Algorithms',
        location: 'Room A215',
      ),
      AvailabilitySlot(
        id: 'p2-m1-2',
        startTime: monday.add(const Duration(hours: 10, minutes: 45)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Office 312',
      ),
      AvailabilitySlot(
        id: 'p2-w1-1',
        startTime: monday.add(const Duration(days: 2, hours: 14)),
        durationMinutes: 30,
        title: 'Consultation – Data Structures',
        location: 'Room A215',
      ),
      AvailabilitySlot(
        id: 'p2-w1-2',
        startTime: monday.add(const Duration(days: 2, hours: 14, minutes: 45)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Office 312',
      ),
    ];
  }

  if (ownerId == 'p3') {
    // Prof. Marie Svobodová – Software Engineering
    return [
      AvailabilitySlot(
        id: 'p3-t1-1',
        startTime: monday.add(const Duration(days: 1, hours: 13)),
        durationMinutes: 30,
        title: 'Consultation – Software Engineering',
        location: 'Room C101',
      ),
      AvailabilitySlot(
        id: 'p3-t1-2',
        startTime: monday.add(const Duration(days: 1, hours: 13, minutes: 45)),
        durationMinutes: 15,
        title: 'Mentoring',
        location: 'Office 405',
      ),
      AvailabilitySlot(
        id: 'p3-th1-1',
        startTime: monday.add(const Duration(days: 3, hours: 9)),
        durationMinutes: 30,
        title: 'Consultation – Database Systems',
        location: 'Lab C205',
      ),
    ];
  }

  if (ownerId == 'd1') {
    // Eva Nováková – Brno Dance School
    return [
      AvailabilitySlot(
        id: 'd1-m1-1',
        startTime: monday.add(const Duration(hours: 16)),
        durationMinutes: 60,
        title: 'Training Session',
        location: 'Studio A',
      ),
      AvailabilitySlot(
        id: 'd1-w1-1',
        startTime: monday.add(const Duration(days: 2, hours: 17)),
        durationMinutes: 60,
        title: 'Training Session',
        location: 'Studio A',
      ),
      AvailabilitySlot(
        id: 'd1-f1-1',
        startTime: monday.add(const Duration(days: 4, hours: 15)),
        durationMinutes: 60,
        title: 'Training Session',
        location: 'Main Hall',
      ),
    ];
  }

  if (ownerId == 'd2') {
    // Petr Horák – Brno Dance School
    return [
      AvailabilitySlot(
        id: 'd2-t1-1',
        startTime: monday.add(const Duration(days: 1, hours: 18)),
        durationMinutes: 60,
        title: 'Training Session',
        location: 'Studio B',
      ),
      AvailabilitySlot(
        id: 'd2-th1-1',
        startTime: monday.add(const Duration(days: 3, hours: 17)),
        durationMinutes: 60,
        title: 'Training Session',
        location: 'Studio B',
      ),
    ];
  }

  return [];
}
