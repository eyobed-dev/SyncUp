import 'package:flutter/material.dart';
import 'package:sync_up/theme/sync_up_theme.dart';
import 'screens/main_screen.dart';

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
      home: const MainScreen(),
    );
  }
}
