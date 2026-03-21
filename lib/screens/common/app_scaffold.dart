import 'package:flutter/material.dart';
import '../../theme/sync_up_theme.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? endDrawer;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final FloatingActionButton? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.endDrawer,
    this.actions,
    this.bottom,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyncUpTheme.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: SyncUpTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: bottom,
        actions: actions,
      ),
      endDrawer: endDrawer,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}