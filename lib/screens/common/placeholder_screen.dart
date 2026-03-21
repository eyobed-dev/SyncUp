import 'package:flutter/material.dart';
import '../../theme/sync_up_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyncUpTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: SyncUpTheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SyncUpTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncUpTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}