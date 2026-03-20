import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'add_schedule_screen.dart';
import 'find_schedule_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    AddScheduleScreen(),
    FindScheduleScreen(),
  ];

  static const _navItems = [
    (icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
    (icon: Icons.add_circle_outline, active: Icons.add_circle, label: 'Add Schedule'),
    (icon: Icons.search_outlined, active: Icons.search, label: 'Find Schedule'),
  ];

  @override
  Widget build(BuildContext context) {
    final useRail = Responsive.isTabletOrLarger(context);

    return Scaffold(
      body: Row(
        children: [
          if (useRail) ...[
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              destinations: _navItems
                  .map((e) => NavigationRailDestination(
                        icon: Icon(e.icon),
                        selectedIcon: Icon(e.active),
                        label: Text(e.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
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
                  .map((e) => BottomNavigationBarItem(
                        icon: Icon(e.icon),
                        activeIcon: Icon(e.active),
                        label: e.label,
                      ))
                  .toList(),
            ),
    );
  }
}
