import 'package:flutter/material.dart';
import '../../theme/sync_up_theme.dart';
import '../../utils/responsive.dart';
import '../common/settings_screen.dart';
import 'teacher_home_screen.dart';
import 'add_schedule_screen.dart';

class TeacherMainScreen extends StatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;
  int _slotDurationMinutes = 15;

  late List<Widget> _screens;

  static const _navItems = [
    (
      icon: Icons.home_outlined,
      active: Icons.home,
      label: 'Home',
    ),
    (
      icon: Icons.add_circle_outline,
      active: Icons.add_circle,
      label: 'Add Schedule',
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
      const TeacherHomeScreen(),
      const AddScheduleScreen(),
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