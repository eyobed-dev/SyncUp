import '../models/schedule_owner.dart';

/// Sample professors and instructors for Find Schedule search.
/// BUT University (Brno University of Technology) and Brno Dance School.
List<ScheduleOwner> getScheduleOwners() {
  return [
    // BUT University – FIT (Faculty of Information Technology)
    const ScheduleOwner(
      id: 'p1',
      name: 'Prof. Alexander Meduna',
      role: 'Professor',
      department: 'FIT, BUT',
      email: 'meduna@fit.vutbr.cz',
    ),
    const ScheduleOwner(
      id: 'p2',
      name: 'Dr. Jan Novák',
      role: 'Associate Professor',
      department: 'FIT, BUT',
      email: 'novak@fit.vutbr.cz',
    ),
    const ScheduleOwner(
      id: 'p3',
      name: 'Prof. Marie Svobodová',
      role: 'Professor',
      department: 'FIT, BUT',
      email: 'svobodova@fit.vutbr.cz',
    ),
    // Brno Dance School
    const ScheduleOwner(
      id: 'd1',
      name: 'Eva Nováková',
      role: 'Dance Instructor',
      department: 'Brno Dance School',
      email: 'novakova@brnodance.cz',
    ),
    const ScheduleOwner(
      id: 'd2',
      name: 'Petr Horák',
      role: 'Dance Instructor',
      department: 'Brno Dance School',
      email: 'horak@brnodance.cz',
    ),
  ];
}
