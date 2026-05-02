import 'package:flutter/material.dart';
import 'package:sync_up/theme/sync_up_theme.dart';
import 'models/app_user_session.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'SyncUp',
      debugShowCheckedModeBanner: false,
      theme: SyncUpTheme.theme,
      home: _session == null
          ? LoginScreen(
              onLoggedIn: (session) => setState(() => _session = session),
            )
          : MainScreen(
              user: _session!,
              onSignOut: () => setState(() => _session = null),
            ),
    );
  }
}
