import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/sample_data.dart';
import '../models/meeting.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../utils/week_calendar.dart';
import 'meeting_list_card.dart';
import 'week_day_selector.dart';

/// Main Meetings tab: same day strip and list rows as [CalendarView] (List tab), plus selection and bulk actions.
class AllMeetingsTab extends StatefulWidget {
  final DateTime weekStart;
  /// Full week schedule (sample + extras − hidden); filtered by [selectedDayIndex] like the List tab.
  final List<Meeting> meetings;
  final ValueNotifier<int> selectedDayIndex;
  final ValueListenable<DateTime>? liveClock;
  /// `false` = top "Add slot" (default time works backward from last meeting); `true` = bottom (forward from last end).
  final void Function(bool addFromBottom) onAddSlot;
  final void Function(Set<String> meetingIds, String apologyMessage) onBulkPostpone;
  /// Remove newly added (empty) slots by id (ids start with `extra-`).
  final void Function(Set<String> meetingIds) onRemoveNewSlots;

  const AllMeetingsTab({
    super.key,
    required this.weekStart,
    required this.meetings,
    required this.selectedDayIndex,
    required this.onAddSlot,
    required this.onBulkPostpone,
    required this.onRemoveNewSlots,
    this.liveClock,
  });

  @override
  State<AllMeetingsTab> createState() => _AllMeetingsTabState();
}

class _AllMeetingsTabState extends State<AllMeetingsTab> {
  final Set<String> _selectedIds = {};

  void _onDayIndexChanged() {
    if (mounted) setState(() => _selectedIds.clear());
  }

  @override
  void initState() {
    super.initState();
    widget.selectedDayIndex.addListener(_onDayIndexChanged);
  }

  @override
  void didUpdateWidget(AllMeetingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) {
      _selectedIds.clear();
    }
    if (oldWidget.selectedDayIndex != widget.selectedDayIndex) {
      oldWidget.selectedDayIndex.removeListener(_onDayIndexChanged);
      widget.selectedDayIndex.addListener(_onDayIndexChanged);
    }
    final valid = widget.meetings.map((m) => m.id).toSet();
    _selectedIds.removeWhere((id) => !valid.contains(id));
  }

  @override
  void dispose() {
    widget.selectedDayIndex.removeListener(_onDayIndexChanged);
    super.dispose();
  }

  String _mailtoQuery(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Set<String> get _selectedExtraIds =>
      _selectedIds.where((id) => id.startsWith('extra-')).toSet();

  Future<void> _confirmRemoveSelected(BuildContext context) async {
    final ids = _selectedExtraIds;
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one new slot to remove'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${ids.length} slot${ids.length == 1 ? '' : 's'}?'),
        content: const Text('This will delete the selected empty slots.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    widget.onRemoveNewSlots(ids);
    setState(() => _selectedIds.removeWhere(ids.contains));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${ids.length} slot${ids.length == 1 ? '' : 's'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmRemoveOne(BuildContext context, Meeting m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove slot?'),
        content: const Text('This will delete the empty slot.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    widget.onRemoveNewSlots({m.id});
    setState(() => _selectedIds.remove(m.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Slot removed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openBulkEmail(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    final selected = widget.meetings.where((m) => _selectedIds.contains(m.id)).toList();
    final names = selected.map((m) => m.participantName).join(', ');
    final subjectController = TextEditingController(text: 'Meeting update');
    final bodyController = TextEditingController(
      text: 'Hello,\n\nI am writing regarding our upcoming meetings.\n\nParticipants: $names\n\n',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email selected'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${selected.length} recipient(s): $names',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: SyncUpTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 4,
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open in email app'),
          ),
        ],
      ),
    );

    if (ok != true) {
      subjectController.dispose();
      bodyController.dispose();
      return;
    }

    final subject = subjectController.text;
    final body = bodyController.text;
    subjectController.dispose();
    bodyController.dispose();

    if (!context.mounted) return;

    final uri = Uri(
      scheme: 'mailto',
      query: _mailtoQuery({
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Draft opened for ${selected.length} meeting(s). Add addresses in your mail app.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app available. Copy the message manually.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openBulkPostpone(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    final n = _selectedIds.length;
    final controller = TextEditingController(
      text:
          "I'm sorry we need to reschedule our meeting. I'll follow up shortly with a new time that works better.",
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Postpone $n meeting${n == 1 ? '' : 's'}?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'An apology message will be recorded for each selected participant. They will be removed from this week\'s schedule (demo).',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: SyncUpTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Apology message',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Postpone all'),
          ),
        ],
      ),
    );

    if (ok != true) {
      controller.dispose();
      return;
    }
    final msg = controller.text.trim();
    controller.dispose();

    if (!context.mounted) return;
    final ids = Set<String>.from(_selectedIds);
    widget.onBulkPostpone(ids, msg.isEmpty ? '(No message)' : msg);
    setState(() => _selectedIds.clear());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Postponed $n meeting(s). Apology logged (demo).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _addSlotButton(BuildContext context, {required bool fromBottom}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => widget.onAddSlot(fromBottom),
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const Text('Add slot'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  List<Meeting> _meetingsForDayIndex(int dayIndex) {
    final weekSunday = startOfWeekSunday(
      DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day),
    );
    final day = weekSunday.add(Duration(days: dayIndex));
    return widget.meetings
        .where((m) {
          final md = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
          final dd = DateTime(day.year, day.month, day.day);
          return md == dd;
        })
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    final outerPadding = Responsive.value(
      context,
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );
    final listPadding = Responsive.value(
      context,
      mobile: 6.0,
      tablet: 8.0,
      desktop: 10.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: outerPadding),
        WeekDaySelector(
          weekStart: widget.weekStart,
          selectedIndex: widget.selectedDayIndex,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(outerPadding, 8, outerPadding, 8),
          child: _addSlotButton(context, fromBottom: false),
        ),
        const Divider(height: 1),
        if (_selectedIds.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: outerPadding, vertical: 8),
            child: Material(
              color: SyncUpTheme.zenGreenLight,
              borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} selected',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openBulkEmail(context),
                      child: const Text('Email'),
                    ),
                    TextButton(
                      onPressed: () => _openBulkPostpone(context),
                      child: const Text('Postpone'),
                    ),
                    TextButton(
                      onPressed: _selectedExtraIds.isEmpty
                          ? null
                          : () => _confirmRemoveSelected(context),
                      child: const Text('Remove'),
                    ),
                    IconButton(
                      tooltip: 'Clear selection',
                      onPressed: () => setState(() => _selectedIds.clear()),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: widget.selectedDayIndex,
            builder: (context, dayIndex, _) {
              final dayMeetings = _meetingsForDayIndex(dayIndex);

              Widget buildList(Meeting? current) {
                if (dayMeetings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: SyncUpTheme.zenGreen.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No meetings this day',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: SyncUpTheme.zenGreen.withValues(alpha: 0.8),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: outerPadding * 2),
                          child: _addSlotButton(context, fromBottom: true),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(listPadding, listPadding, listPadding, 12),
                  itemCount: dayMeetings.length,
                  itemBuilder: (context, i) {
                    final m = dayMeetings[i];
                    final selected = _selectedIds.contains(m.id);
                    final isExtra = m.id.startsWith('extra-');
                    return RepaintBoundary(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          border: selected
                              ? Border.all(
                                  color: SyncUpTheme.primary.withValues(alpha: 0.55),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: MeetingListCard(
                          meeting: m,
                          colorIndex: i,
                          currentMeeting: current,
                          leading: Checkbox(
                            value: selected,
                            onChanged: (_) {
                              setState(() {
                                if (selected) {
                                  _selectedIds.remove(m.id);
                                } else {
                                  _selectedIds.add(m.id);
                                }
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          trailing: isExtra
                              ? IconButton(
                                  tooltip: 'Remove slot',
                                  onPressed: () => _confirmRemoveOne(context, m),
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                );
              }

              final live = widget.liveClock;
              if (live == null) {
                return buildList(getCurrentMeetingFromList(widget.meetings));
              }
              return ValueListenableBuilder<DateTime>(
                valueListenable: live,
                builder: (context, _, __) =>
                    buildList(getCurrentMeetingFromList(widget.meetings)),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(outerPadding, 8, outerPadding, outerPadding),
            child: _addSlotButton(context, fromBottom: true),
          ),
        ),
      ],
    );
  }
}
