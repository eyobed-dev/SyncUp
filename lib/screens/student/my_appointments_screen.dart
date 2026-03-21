import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../theme/sync_up_theme.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final List<Appointment> _appointments = [
    const Appointment(
      id: '1',
      professorName: 'Prof. Adam Herout',
      department: 'Computer Science',
      dateLabel: 'Mar 6',
      timeLabel: '13:00–13:30',
      topic: 'UXI Project',
      avatarLetter: 'A',
    ),
    const Appointment(
      id: '2',
      professorName: 'Prof. Jana Novak',
      department: 'Data Science',
      dateLabel: 'Mar 8',
      timeLabel: '10:00–10:30',
      topic: 'Consultation',
      avatarLetter: 'J',
    ),
  ];

  void _cancelAppointment(String id) {
    setState(() {
      _appointments.removeWhere((e) => e.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment canceled')),
    );
  }

  void _showDetails(Appointment item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.professorName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Department: ${item.department}'),
            Text('Date: ${item.dateLabel}'),
            Text('Time: ${item.timeLabel}'),
            Text('Topic: ${item.topic}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyncUpTheme.background,
      body: _appointments.isEmpty
          ? Center(
              child: Text(
                'No appointments yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SyncUpTheme.textSecondary,
                    ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = _appointments[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SyncUpTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SyncUpTheme.border),
                    boxShadow: SyncUpTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                SyncUpTheme.primary.withOpacity(0.12),
                            child: Text(
                              item.avatarLetter,
                              style: const TextStyle(
                                color: SyncUpTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.professorName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: SyncUpTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.department,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: SyncUpTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Date: ${item.dateLabel}'),
                      const SizedBox(height: 4),
                      Text('Time: ${item.timeLabel}'),
                      const SizedBox(height: 4),
                      Text('Topic: ${item.topic}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showDetails(item),
                            child: const Text('View'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () => _cancelAppointment(item.id),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}