import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';
import 'package:sync_up/theme/sync_up_colors.dart';

/// End drawer showing user profile details.
class UserProfileDrawer extends StatelessWidget {
  final String displayName;
  final String username;
  final String roleLabel;
  final String? userId;
  final String? email;
  final String? phone;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onSignOutTap;

  const UserProfileDrawer({
    super.key,
    required this.displayName,
    required this.username,
    required this.roleLabel,
    this.userId,
    this.email,
    this.phone,
    this.onSettingsTap,
    this.onSignOutTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUsername = username.trim().toLowerCase();
    final profileEmail = (email ?? '').trim().isNotEmpty
        ? email!.trim()
        : (normalizedUsername.contains('@')
              ? normalizedUsername
              : '$normalizedUsername@fit.cvut.cz');
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(SyncUpTheme.space24),
              color: context.colors.primaryLight,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: context.colors.primary,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: context.colors.surface,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: SyncUpTheme.space16),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profileEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                  ),
                  if ((phone ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: context.colors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          phone!.trim(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                  if ((userId ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${userId!.trim()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(SyncUpTheme.radiusPill),
                    ),
                    child: Text(
                      roleLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: context.colors.primary,
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
                    leading: Icon(Icons.settings_outlined, color: context.colors.textSecondary),
                    title: Text(
                      'Preferences',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.colors.textPrimary,
                          ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onSettingsTap?.call();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: context.colors.textSecondary),
                    title: Text(
                      'Help',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.colors.textPrimary,
                          ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Help'),
                          content: const Text(
                            'SyncUp helps professors publish meeting availability and helps students find and book slots. '
                            'Open slots become booked meetings, and weekly views keep everyone aligned.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.logout, color: context.colors.textSecondary),
                    title: Text(
                      'Sign out',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onSignOutTap?.call();
                    },
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
