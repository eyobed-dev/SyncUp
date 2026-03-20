import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';

/// Placeholder user data – replace with real auth/user model.
const _userName = 'Prof Alexander Meduna';
const _userEmail = 'meduna@fit.cvut.cz';
const _userPhone = '+420 224 359 814';
const _userRole = 'Teacher';

/// End drawer showing user profile details.
class UserProfileDrawer extends StatelessWidget {
  final VoidCallback? onSettingsTap;

  const UserProfileDrawer({super.key, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(SyncUpTheme.space24),
              color: SyncUpTheme.primaryLight,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: SyncUpTheme.primary,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: SyncUpTheme.space16),
                  Text(
                    _userName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: SyncUpTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SyncUpTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: SyncUpTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _userPhone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: SyncUpTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SyncUpTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(SyncUpTheme.radiusPill),
                    ),
                    child: Text(
                      _userRole,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: SyncUpTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: SyncUpTheme.textSecondary),
                    title: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: SyncUpTheme.textPrimary,
                          ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onSettingsTap?.call();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications_outlined, color: SyncUpTheme.textSecondary),
                    title: Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: SyncUpTheme.textPrimary,
                          ),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: SyncUpTheme.textSecondary),
                    title: Text(
                      'Help',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: SyncUpTheme.textPrimary,
                          ),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.logout, color: SyncUpTheme.textSecondary),
                    title: Text(
                      'Sign out',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
