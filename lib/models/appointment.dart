class Appointment {
  final String id;
  final String professorName;
  final String department;
  final String dateLabel;
  final String timeLabel;
  final String topic;
  final String avatarLetter;

  const Appointment({
    required this.id,
    required this.professorName,
    required this.department,
    required this.dateLabel,
    required this.timeLabel,
    required this.topic,
    required this.avatarLetter,
  });
}