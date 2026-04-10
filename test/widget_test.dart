// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sync_up/data/backend_seed.dart';
import 'package:sync_up/data/past_session_note_templates.dart';
import 'package:sync_up/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Future.wait([
      PastSessionNoteTemplates.load(),
      BackendSeed.load(),
    ]);
  });

  testWidgets('SyncUp app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SyncUpApp());
    expect(find.text('SyncUp'), findsOneWidget);
  });
}
