import 'package:flutter/material.dart';
import '../../theme/sync_up_theme.dart';
import '../../utils/responsive.dart';
import '../common/settings_screen.dart';
import 'find_schedule_screen.dart';
import 'my_appointments_screen.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;
  int _slotDurationMinutes = 15;

  late List<Widget> _screens;

  static const _navItems = [
    (
      icon: Icons.search_outlined,
      active: Icons.search,
      label: 'Find',
    ),
    (
      icon: Icons.event_note_outlined,
      active: Icons.event_note,
      label: 'My Appointments',
    ),
    (
      icon: Icons.settings_outlined,
      active: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rebuildScreens();
  }

  void _rebuildScreens() {
    _screens = [
      const FindScheduleScreen(),
      const MyAppointmentsScreen(),
      SettingsScreen(
        slotDurationMinutes: _slotDurationMinutes,
        onSlotDurationChanged: (v) {
          setState(() {
            _slotDurationMinutes = v;
            _rebuildScreens();
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final useRail = Responsive.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: SyncUpTheme.background,
      body: Row(
        children: [
          if (useRail)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              destinations: _navItems
                  .map(
                    (e) => NavigationRailDestination(
                      icon: Icon(e.icon),
                      selectedIcon: Icon(e.active),
                      label: Text(e.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              items: _navItems
                  .map(
                    (e) => BottomNavigationBarItem(
                      icon: Icon(e.icon),
                      activeIcon: Icon(e.active),
                      label: e.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}