import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../widgets/syncup_logo.dart';
import 'package:sync_up/theme/sync_up_colors.dart';
import 'package:sync_up/main.dart';

/// Preferences page with communication and tracking toggles.
class SettingsScreen extends StatefulWidget {
  final int slotDurationMinutes;
  final ValueChanged<int>? onSlotDurationChanged;

  const SettingsScreen({
    super.key,
    required this.slotDurationMinutes,
    this.onSlotDurationChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _selectedSlotDurationMinutes;
  bool _allowAlertNotifications = true;
  bool _allowEmailCommunications = true;
  bool _trackOngoingMeetings = true;

  @override
  void initState() {
    super.initState();
    _selectedSlotDurationMinutes = widget.slotDurationMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isMobile(context);
    return Scaffold(
      appBar: AppBar(
        title: SyncUpLogo(size: 28, compact: compact),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onSlotDurationChanged?.call(_selectedSlotDurationMinutes);
            Navigator.pop(context, _selectedSlotDurationMinutes);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SyncUpTheme.space24),
        children: [
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: SyncUpTheme.space24),
          AnimatedBuilder(
            animation: themeController,
            builder: (context, child) {
              return ListTile(
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {themeController.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    themeController.setThemeMode(newSelection.first);
                  },
                ),
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            value: _allowAlertNotifications,
            onChanged: (v) => setState(() => _allowAlertNotifications = v),
            title: const Text('Allow alert notifications'),
          ),
          SwitchListTile(
            value: _allowEmailCommunications,
            onChanged: (v) => setState(() => _allowEmailCommunications = v),
            title: const Text('Allow email communications'),
          ),
          SwitchListTile(
            value: _trackOngoingMeetings,
            onChanged: (v) => setState(() => _trackOngoingMeetings = v),
            title: const Text('Track ongoing meetings'),
          ),
        ],
      ),
    );
  }
}
