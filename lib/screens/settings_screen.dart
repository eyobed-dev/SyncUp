import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../widgets/syncup_logo.dart';
import '../widgets/slots_view.dart';

/// Settings page with slot duration and other preferences.
class SettingsScreen extends StatelessWidget {
  final int slotDurationMinutes;
  final ValueChanged<int>? onSlotDurationChanged;

  const SettingsScreen({
    super.key,
    required this.slotDurationMinutes,
    this.onSlotDurationChanged,
  });

  static String _formatSlotDuration(int mins) {
    if (mins < 60) return '$mins min';
    if (mins == 60) return '1 hr';
    return '${mins ~/ 60} hrs';
  }

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isMobile(context);
    return Scaffold(
      appBar: AppBar(
        title: SyncUpLogo(size: 28, compact: compact),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SyncUpTheme.space24),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: SyncUpTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: SyncUpTheme.space24),
          Text(
            'Time slot duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SyncUpTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grid slot size for the calendar view',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SyncUpTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          ...slotDurationOptions.map((mins) {
            return RadioListTile<int>(
              title: Text(_formatSlotDuration(mins)),
              value: mins,
              groupValue: slotDurationMinutes,
              onChanged: (v) {
                if (v != null) {
                  onSlotDurationChanged?.call(v);
                  Navigator.pop(context, v);
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
