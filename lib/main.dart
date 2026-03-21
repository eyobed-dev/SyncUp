import 'package:flutter/material.dart';
import 'theme/sync_up_theme.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const SyncUpApp());
}

class SyncUpApp extends StatelessWidget {
  const SyncUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncUp',
      debugShowCheckedModeBanner: false,
      theme: SyncUpTheme.theme,
      home: const LoginScreen(),
    );
  }
}