import 'package:flutter/material.dart';
import '../models/app_user_session.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'add_schedule_screen.dart';
import 'find_schedule_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.user,
    this.onSignOut,
  });

  final AppUserSession user;
  final VoidCallback? onSignOut;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final useRail = Responsive.isTabletOrLarger(context);
    final isOwner = widget.user.role == AppUserRole.owner;
    final roleLabel = isOwner ? 'Teacher' : 'Student';
    final screens = isOwner
        ? [
            HomeScreen(
              ownerId: widget.user.ownerId!,
              displayName: widget.user.displayName,
              username: widget.user.username,
              roleLabel: roleLabel,
              userId: widget.user.userId,
              onSignOut: widget.onSignOut,
            ),
            AddScheduleScreen(
              ownerId: widget.user.ownerId!,
              displayName: widget.user.displayName,
              username: widget.user.username,
              roleLabel: roleLabel,
              userId: widget.user.userId,
              onSignOut: widget.onSignOut,
            ),
          ]
        : [
            FindScheduleScreen(
              attendeeName: widget.user.displayName,
              attendeeUserId: widget.user.userId,
              profileDisplayName: widget.user.displayName,
              profileUsername: widget.user.username,
              profileRoleLabel: roleLabel,
              profileUserId: widget.user.userId,
              onSignOut: widget.onSignOut,
            ),
          ];
    final navItems = isOwner
        ? const [
            (icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
            (
              icon: Icons.add_circle_outline,
              active: Icons.add_circle,
              label: 'Add Schedule',
            ),
          ]
        : const [];

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          if (useRail && navItems.length >= 2) ...[
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              destinations: navItems
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
                  children: screens,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: useRail || navItems.length < 2
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              items: navItems
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
