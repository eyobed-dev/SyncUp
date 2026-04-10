import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads prior-session **wording** from [assets/data/backend_seed.json] key `sessionNoteTemplates`.
/// Logic (which rows get history, dates, etc.) stays in Dart; JSON is only copy + `{course}` merge.
class PastSessionNoteTemplates {
  PastSessionNoteTemplates._({
    required this.placeholder,
    required this.recentDiscussions,
    required this.recentTodos,
    required this.recentNotes,
    required this.olderDiscussions,
    required this.olderTodos,
  });

  final String placeholder;
  final List<String> recentDiscussions;
  final List<String> recentTodos;
  final String recentNotes;
  final List<String> olderDiscussions;
  final List<String> olderTodos;

  static PastSessionNoteTemplates? _instance;

  static PastSessionNoteTemplates get instance => _instance ??= _defaults();

  /// Call from `main()` after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/backend_seed.json');
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final nested = root['sessionNoteTemplates'];
      if (nested is Map) {
        _instance = _fromJson(Map<String, dynamic>.from(nested));
      } else {
        _instance = _defaults();
      }
    } catch (_) {
      _instance = _defaults();
    }
  }

  static PastSessionNoteTemplates _fromJson(Map<String, dynamic> map) {
    final ph = map['placeholder'] as String? ?? '{course}';
    final recent = map['recent'] as Map<String, dynamic>? ?? {};
    final older = map['older'] as Map<String, dynamic>? ?? {};
    return PastSessionNoteTemplates._(
      placeholder: ph,
      recentDiscussions: _strList(recent['discussions']),
      recentTodos: _strList(recent['todos']),
      recentNotes: recent['notes'] as String? ?? '',
      olderDiscussions: _strList(older['discussions']),
      olderTodos: _strList(older['todos']),
    );
  }

  static List<String> _strList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => '$e').toList();
  }

  static PastSessionNoteTemplates _defaults() {
    return PastSessionNoteTemplates._fromJson({
      'placeholder': '{course}',
      'recent': {
        'discussions': [
          'Check-in on {course} — reviewed progress and blockers',
          'Aligned next steps from the last session on {course}',
        ],
        'todos': [
          'Apply agreed actions before the next scheduled slot',
          'Bring questions tied to {course} for follow-up',
        ],
        'notes': 'Brief note associated with {course}.',
      },
      'older': {
        'discussions': [
          'Planning session for {course} — clarified goals for the term',
          'Reviewed materials the student selected for this focus area',
        ],
        'todos': [
          'Confirm readings or tasks for {course} before next session',
        ],
      },
    });
  }

  String _merge(String template, String course) =>
      template.replaceAll(placeholder, course);

  List<String> mergeDiscussionsRecent(String course) =>
      recentDiscussions.map((s) => _merge(s, course)).toList();

  List<String> mergeTodosRecent(String course) =>
      recentTodos.map((s) => _merge(s, course)).toList();

  String mergeNotesRecent(String course) => _merge(recentNotes, course);

  List<String> mergeDiscussionsOlder(String course) =>
      olderDiscussions.map((s) => _merge(s, course)).toList();

  List<String> mergeTodosOlder(String course) =>
      olderTodos.map((s) => _merge(s, course)).toList();
}
