import 'package:flutter/material.dart';
import 'package:sync_up/theme/sync_up_theme.dart';
import 'package:sync_up/theme/theme_controller.dart';
import 'models/app_user_session.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

final themeController = ThemeController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.init();
  runApp(const SyncUpApp());
}

class SyncUpApp extends StatefulWidget {
  const SyncUpApp({super.key});

  @override
  State<SyncUpApp> createState() => _SyncUpAppState();
}

class _SyncUpAppState extends State<SyncUpApp> {
  AppUserSession? _session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'SyncUp',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: SyncUpTheme.theme,
          darkTheme: SyncUpTheme.darkTheme,
          home: _session == null
              ? LoginScreen(
                  onLoggedIn: (session) => setState(() => _session = session),
                )
              : MainScreen(
                  user: _session!,
                  onSignOut: () => setState(() => _session = null),
                ),
        );
      },
    );
  }
}
