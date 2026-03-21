import 'package:flutter/material.dart';
import '../../theme/sync_up_theme.dart';
import '../student/student_main_screen.dart';
import '../teacher/teacher_main_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyncUpTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SyncUp',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SyncUpTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose your role',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SyncUpTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),
                _RoleButton(
                  title: 'Teacher',
                  icon: Icons.school_outlined,
                  subtitle: 'Manage schedule and availability',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherMainScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'Student',
                  icon: Icons.person_search_outlined,
                  subtitle: 'Find professors and make appointments',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentMainScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SyncUpTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SyncUpTheme.border),
            boxShadow: SyncUpTheme.cardShadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: SyncUpTheme.primary.withOpacity(0.12),
                child: Icon(icon, color: SyncUpTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SyncUpTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SyncUpTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: SyncUpTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}