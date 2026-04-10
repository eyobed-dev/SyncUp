import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/meeting.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../utils/week_calendar.dart';
import 'meeting_list_card.dart';
import 'week_day_selector.dart';

/// Meetings tab: day summary + list rows, plus selection and bulk actions.
class AllMeetingsTab extends StatefulWidget {
  final DateTime weekStart;
  /// Full week schedule (seed meetings + extras − hidden); filtered by [selectedDayIndex] like the List tab.
  final List<Meeting> meetings;
  final ValueNotifier<int> selectedDayIndex;
  final ValueListenable<DateTime>? liveClock;
  /// `true` = bottom "Add meeting" (forward from last end).
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

  Future<bool?> _showBulkEmailDialog(
    BuildContext context, {
    required List<Meeting> selected,
    required String names,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _BulkEmailDialog(selected: selected, names: names),
    );
  }

  String _mergePostponeTemplate(String template, Meeting m) {
    final safeName = m.participantName.trim().isEmpty ? 'Student' : m.participantName.trim();
    final date =
        '${m.startTime.year.toString().padLeft(4, '0')}-${m.startTime.month.toString().padLeft(2, '0')}-${m.startTime.day.toString().padLeft(2, '0')}';
    final time =
        '${m.startTime.hour.toString().padLeft(2, '0')}:${m.startTime.minute.toString().padLeft(2, '0')}';
    return template
        .replaceAll('{student}', safeName)
        .replaceAll('{name}', safeName)
        .replaceAll('{date}', date)
        .replaceAll('{time}', time)
        .replaceAll('{room}', 'LL4');
  }

  String _selectedDayLabel(DateTime weekStart, int dayIndex) {
    final weekSunday = startOfWeekSunday(DateTime(weekStart.year, weekStart.month, weekStart.day));
    final day = weekSunday.add(Duration(days: dayIndex));
    return '${dayLongNamesSunFirst[dayIndex]} ${day.day}';
  }

  Future<void> _pickDay(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select day',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SyncUpTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 10),
              WeekDaySelector(
                weekStart: widget.weekStart,
                selectedIndex: widget.selectedDayIndex,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  bool _isEmptySlot(Meeting m) =>
      m.participantName.trim().toLowerCase() == 'open slot';

  Set<String> get _selectedEmptySlotIds => widget.meetings
      .where((m) => _selectedIds.contains(m.id))
      .where(_isEmptySlot)
      .map((m) => m.id)
      .toSet();

  Future<void> _confirmRemoveSelected(BuildContext context) async {
    final ids = _selectedEmptySlotIds;
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one empty slot to remove'),
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

  Widget _dialogStudentNamesBlock(BuildContext context, List<Meeting> meetings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Students (${meetings.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: SyncUpTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SyncUpTheme.zenGreenLight,
            borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
            border: Border.all(color: SyncUpTheme.border),
          ),
          child: ListView.separated(
            shrinkWrap: meetings.length <= 5,
            physics: meetings.length > 5
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: meetings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final name = meetings[i].participantName.trim();
              final label = name.isEmpty ? '—' : name;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person, size: 22, color: SyncUpTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            height: 1.35,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openBulkEmail(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    final selected = widget.meetings.where((m) => _selectedIds.contains(m.id)).toList();
    final names = selected.map((m) => m.participantName).join(', ');
    final ok = await _showBulkEmailDialog(context, selected: selected, names: names);
    if (ok != true || !context.mounted) return;

    setState(() => _selectedIds.clear());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

class _BulkEmailDialog extends StatefulWidget {
  const _BulkEmailDialog({required this.selected, required this.names});

  final List<Meeting> selected;
  final String names;

  @override
  State<_BulkEmailDialog> createState() => _BulkEmailDialogState();
}

class _BulkEmailDialogState extends State<_BulkEmailDialog> {
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: 'Schedule update');
    _bodyController = TextEditingController(
      text:
          'Hello,\n\nI am writing regarding upcoming sessions.\n\nParticipants: ${widget.names}\n\n',
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    // Demo: treat as sent.
    if (kDebugMode) {
      debugPrint('Bulk email subject: ${_subjectController.text}');
      debugPrint('Bulk email body: ${_bodyController.text}');
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxW = (size.width * 0.92).clamp(320.0, 640.0);
    final maxH = size.height * 0.88;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Email selected',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SyncUpTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.selected.length} student(s) will be emailed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncUpTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              if (_isSending) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 12),
              ],
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogStudentNamesBlock(context, widget.selected),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _subjectController,
                        enabled: !_isSending,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bodyController,
                        enabled: !_isSending,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        minLines: 6,
                        maxLines: 12,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSending ? null : _send,
                    child: Text(_isSending ? 'Sending…' : 'Send email'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

  Future<void> _openBulkPostpone(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    final selected = widget.meetings.where((m) => _selectedIds.contains(m.id)).toList();
    final n = selected.length;
    final controller = TextEditingController(
      text:
          "Hi {student},\n\nI'm sorry—we need to reschedule your session on {date} at {time} (Room {room}).\n\nI'll follow up shortly with a new time that works better.\n\nThank you,\n",
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        final maxW = (size.width * 0.92).clamp(320.0, 640.0);
        final maxH = size.height * 0.88;
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            var isWorking = false;

            Future<void> postpone() async {
              if (isWorking) return;
              setLocalState(() => isWorking = true);
              await Future<void>.delayed(const Duration(milliseconds: 900));
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Postpone $n session${n == 1 ? '' : 's'}?',
                        style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SyncUpTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'An apology email will be sent to each participant below (demo).',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: SyncUpTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mail-merge fields: {student}, {date}, {time}, {room}',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: SyncUpTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (isWorking) ...[
                        const LinearProgressIndicator(minHeight: 3),
                        const SizedBox(height: 12),
                      ],
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _dialogStudentNamesBlock(ctx, selected),
                              const SizedBox(height: 20),
                              TextField(
                                controller: controller,
                                enabled: !isWorking,
                                decoration: const InputDecoration(
                                  labelText: 'Apology message',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                minLines: 5,
                                maxLines: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed:
                                isWorking ? null : () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: isWorking ? null : postpone,
                            child: Text(isWorking ? 'Working…' : 'Postpone & send'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (ok != true) {
      controller.dispose();
      return;
    }
    final msg = controller.text.trim();
    controller.dispose();

    if (!context.mounted) return;
    final ids = Set<String>.from(_selectedIds);
    final template = msg.isEmpty ? '(No message)' : msg;
    // Demo mail-merge: generate one personalized message per student.
    if (kDebugMode) {
      for (final m in selected) {
        debugPrint('Postpone mail-merge to ${m.participantName}:');
        debugPrint(_mergePostponeTemplate(template, m));
      }
    }
    widget.onBulkPostpone(ids, template);
    setState(() => _selectedIds.clear());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postponed. Email sent.'),
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
        label: const Text('Add meeting'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
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
    final dayMeetings = _meetingsForDayIndex(widget.selectedDayIndex.value);
    final dayMeetingIds = dayMeetings.map((m) => m.id).toSet();
    final allSelectedForDay =
        dayMeetingIds.isNotEmpty && _selectedIds.containsAll(dayMeetingIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: outerPadding),
        Padding(
          padding: EdgeInsets.fromLTRB(outerPadding, 4, outerPadding, 10),
          child: ValueListenableBuilder<int>(
            valueListenable: widget.selectedDayIndex,
            builder: (context, dayIndex, _) {
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                  onTap: () => _pickDay(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 18, color: SyncUpTheme.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedDayLabel(widget.weekStart, dayIndex),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: SyncUpTheme.textPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.expand_more, color: SyncUpTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        if (_selectedIds.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: outerPadding, vertical: 8),
            child: Material(
              color: SyncUpTheme.zenGreenLight,
              borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 36, maxWidth: 56),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: SyncUpTheme.border),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${_selectedIds.length}',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                height: 1,
                                color: SyncUpTheme.textPrimary,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: dayMeetingIds.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        if (allSelectedForDay) {
                                          _selectedIds.removeWhere(dayMeetingIds.contains);
                                        } else {
                                          _selectedIds.addAll(dayMeetingIds);
                                        }
                                      });
                                    },
                              child: Text(allSelectedForDay ? 'Deselect all' : 'Select all'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _openBulkEmail(context),
                              child: const Text('Email'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _openBulkPostpone(context),
                              child: const Text('Postpone'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                      onPressed: _selectedEmptySlotIds.isEmpty
                                  ? null
                                  : () => _confirmRemoveSelected(context),
                              child: const Text('Remove'),
                            ),
                            IconButton(
                              tooltip: 'Clear selection',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() => _selectedIds.clear()),
                              icon: const Icon(Icons.close, size: 20),
                            ),
                          ],
                        ),
                      ),
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
                          'No sessions this day',
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

                final omitTopicInList =
                    Meeting.uniformNonEmptyTopicIfAllSame(dayMeetings) != null;

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(listPadding, listPadding, listPadding, 12),
                  itemCount: dayMeetings.length,
                  itemBuilder: (context, i) {
                    final m = dayMeetings[i];
                    final selected = _selectedIds.contains(m.id);
                    final isEmptySlot = _isEmptySlot(m);
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
                          omitTopicInListTitle: omitTopicInList,
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
                          trailing: isEmptySlot
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
