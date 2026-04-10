import 'package:flutter/material.dart';
import 'package:sync_up/data/backend_seed.dart';
import 'package:sync_up/data/past_session_note_templates.dart';
import 'package:sync_up/theme/sync_up_theme.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    PastSessionNoteTemplates.load(),
    BackendSeed.load(),
  ]);
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
