import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../theme/sync_up_theme.dart';
import '../utils/week_calendar.dart';
import 'package:sync_up/theme/sync_up_colors.dart';

// ─── Public entry point ───────────────────────────────────────────────────────

/// Shows a 3-step stepper bottom sheet for adding schedule slots.
/// Returns the list of [Meeting]s to add, or null if cancelled.
Future<List<Meeting>?> showAddSlotSheet({
  required BuildContext context,
  required String ownerId,
  required DateTime weekStart,
  required int initialDayIndex,
  required int slotDurationMinutes,
  required List<Meeting> existingMeetings,
}) {
  return showModalBottomSheet<List<Meeting>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AddSlotSheet(
      ownerId: ownerId,
      weekStart: weekStart,
      initialDayIndex: initialDayIndex,
      slotDurationMinutes: slotDurationMinutes,
      existingMeetings: existingMeetings,
    ),
  );
}

// ─── Internal state ───────────────────────────────────────────────────────────

enum _Step { configure, review }

class _SlotDraft {
  final TimeOfDay time;
  final int durationMinutes;
  final int dayIndex;
  final int breakAfterMinutes;
  final bool isOnline;
  final String meetingLink;

  const _SlotDraft({
    required this.time,
    required this.durationMinutes,
    required this.dayIndex,
    required this.breakAfterMinutes,
    required this.isOnline,
    required this.meetingLink,
  });
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class _AddSlotSheet extends StatefulWidget {
  final String ownerId;
  final DateTime weekStart;
  final int initialDayIndex;
  final int slotDurationMinutes;
  final List<Meeting> existingMeetings;

  const _AddSlotSheet({
    required this.ownerId,
    required this.weekStart,
    required this.initialDayIndex,
    required this.slotDurationMinutes,
    required this.existingMeetings,
  });

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  _Step _step = _Step.configure;

  // Step 1 state
  late int _dayIndex;
  late int _duration;
  late TimeOfDay _slotTime;
  int _breakAfter = 0;
  bool _isOnline = false;
  String _meetingLink = '';

  // Batch
  final List<_SlotDraft> _batch = [];

  static const _durations = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];
  static const _breaks = [0, 5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _dayIndex = widget.initialDayIndex.clamp(0, 6);
    _duration = _durations.contains(widget.slotDurationMinutes)
        ? widget.slotDurationMinutes
        : 30;
    _slotTime = _defaultTime(_dayIndex, _duration);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  DateTime get _weekSunday =>
      startOfWeekSunday(DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day));

  TimeOfDay _defaultTime(int dayIndex, int durationMinutes) {
    final day = _weekSunday.add(Duration(days: dayIndex));
    final meetings = widget.existingMeetings.where((m) {
      final md = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
      return md == DateTime(day.year, day.month, day.day);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (meetings.isEmpty) return const TimeOfDay(hour: 8, minute: 0);
    return TimeOfDay.fromDateTime(meetings.last.endTime);
  }

  bool _overlaps(DateTime aStart, int aMin, DateTime bStart, int bMin) {
    final aEnd = aStart.add(Duration(minutes: aMin));
    final bEnd = bStart.add(Duration(minutes: bMin));
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  bool _hasExistingClash(DateTime start, int dur) {
    return widget.existingMeetings.any((m) {
      final md = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
      final sd = DateTime(start.year, start.month, start.day);
      return md == sd && _overlaps(start, dur, m.startTime, m.durationMinutes);
    });
  }

  bool _hasBatchClash(_SlotDraft draft, DateTime draftStart) {
    for (final other in _batch) {
      if (identical(other, draft)) continue;
      final od = _weekSunday.add(Duration(days: other.dayIndex));
      final oStart = DateTime(od.year, od.month, od.day, other.time.hour, other.time.minute);
      final sd = DateTime(draftStart.year, draftStart.month, draftStart.day);
      final oSd = DateTime(oStart.year, oStart.month, oStart.day);
      if (sd == oSd && _overlaps(draftStart, draft.durationMinutes, oStart, other.durationMinutes)) {
        return true;
      }
    }
    return false;
  }

  DateTime _draftStart(_SlotDraft d) {
    final day = _weekSunday.add(Duration(days: d.dayIndex));
    return DateTime(day.year, day.month, day.day, d.time.hour, d.time.minute);
  }

  Meeting _meetingFromDraft(_SlotDraft d) {
    final start = _draftStart(d);
    final link = d.meetingLink.trim();
    return Meeting(
      id: 'extra-${DateTime.now().millisecondsSinceEpoch}-${start.microsecondsSinceEpoch}',
      participantName: 'Open slot',
      startTime: start,
      durationMinutes: d.durationMinutes,
      location: d.isOnline ? (link.isEmpty ? 'Online' : 'Online • $link') : 'Room LL4',
    );
  }

  int get _addableCount => _batch.where((d) {
        final start = _draftStart(d);
        return !_hasExistingClash(start, d.durationMinutes) && !_hasBatchClash(d, start);
      }).length;

  // ─── Actions ────────────────────────────────────────────────────────────────

  void _addToBatch() {
    if (_isOnline && _meetingLink.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a meeting link for online slots.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final draft = _SlotDraft(
      time: _slotTime,
      durationMinutes: _duration,
      dayIndex: _dayIndex,
      breakAfterMinutes: _breakAfter,
      isOnline: _isOnline,
      meetingLink: _meetingLink.trim(),
    );
    final nextDt = DateTime(2000, 1, 1, _slotTime.hour, _slotTime.minute)
        .add(Duration(minutes: _duration + _breakAfter));
    setState(() {
      _batch.add(draft);
      _slotTime = TimeOfDay(hour: nextDt.hour % 24, minute: nextDt.minute);
      // Removed auto-switch to _Step.batch to allow adding multiple quickly
    });
    // Transient feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Slot added to batch'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Review',
          onPressed: () => setState(() => _step = _Step.review),
        ),
      ),
    );
  }

  void _confirm() {
    final out = _batch.where((d) {
      final start = _draftStart(d);
      return !_hasExistingClash(start, d.durationMinutes) && !_hasBatchClash(d, start);
    }).map(_meetingFromDraft).toList();
    Navigator.of(context).pop(out);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, mq.viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepHeader(step: _step),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _step == _Step.configure
                      ? _ConfigureStep(
                          key: const ValueKey('configure'),
                          dayIndex: _dayIndex,
                          slotTime: _slotTime,
                          duration: _duration,
                          breakAfter: _breakAfter,
                          isOnline: _isOnline,
                          meetingLink: _meetingLink,
                          weekSunday: _weekSunday,
                          durations: _durations,
                          breaks: _breaks,
                          onDayChanged: (v) => setState(() => _dayIndex = v),
                          onTimeChanged: (t) => setState(() => _slotTime = t),
                          onDurationChanged: (d) => setState(() => _duration = d),
                          onBreakChanged: (b) => setState(() => _breakAfter = b),
                          onOnlineChanged: (v) => setState(() => _isOnline = v),
                          onLinkChanged: (l) => setState(() => _meetingLink = l),
                        )
                      : _BatchStep(
                          key: const ValueKey('batch'),
                          batch: _batch,
                          weekSunday: _weekSunday,
                          hasExistingClash: _hasExistingClash,
                          hasBatchClash: _hasBatchClash,
                          draftStart: _draftStart,
                          onRemove: (d) => setState(() => _batch.remove(d)),
                          onAddMore: () => setState(() => _step = _Step.configure),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StepActions(
              step: _step,
              batchCount: _batch.length,
              addableCount: _addableCount,
              onAddToBatch: _addToBatch,
              onGoToReview: () => setState(() => _step = _Step.review),
              onGoToConfigure: () => setState(() => _step = _Step.configure),
              onConfirm: _confirm,
              onCancel: () => Navigator.of(context).pop(null),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step header ─────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final _Step step;
  const _StepHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    final steps = ['Configure', 'Review batch'];
    final current = step.index;
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i == current;
        final done = i < current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || active ? context.colors.primary : context.colors.border,
                    ),
                    child: Center(
                      child: done
                          ? Icon(Icons.check, size: 13, color: context.colors.surface)
                          : Text('${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: active ? context.colors.surface : context.colors.textSecondary,
                              )),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(steps[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? context.colors.textPrimary : context.colors.textSecondary,
                        )),
                  ),
                ]),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: done ? 1.0 : active ? 0.7 : 0.0,
                  minHeight: 2,
                  backgroundColor: context.colors.border,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Step 1: Configure ────────────────────────────────────────────────────────

class _ConfigureStep extends StatelessWidget {
  final int dayIndex;
  final TimeOfDay slotTime;
  final int duration;
  final int breakAfter;
  final bool isOnline;
  final String meetingLink;
  final DateTime weekSunday;
  final List<int> durations;
  final List<int> breaks;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<int> onBreakChanged;
  final ValueChanged<bool> onOnlineChanged;
  final ValueChanged<String> onLinkChanged;

  const _ConfigureStep({
    super.key,
    required this.dayIndex,
    required this.slotTime,
    required this.duration,
    required this.breakAfter,
    required this.isOnline,
    required this.meetingLink,
    required this.weekSunday,
    required this.durations,
    required this.breaks,
    required this.onDayChanged,
    required this.onTimeChanged,
    required this.onDurationChanged,
    required this.onBreakChanged,
    required this.onOnlineChanged,
    required this.onLinkChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Select Day',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                )),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final sel = dayIndex == i;
              return ChoiceChip(
                label: Text(dayShortNamesSunFirst[i]),
                selected: sel,
                onSelected: (s) {
                  if (s) onDayChanged(i);
                },
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? context.colors.surface : context.colors.textPrimary,
                ),
                selectedColor: context.colors.primary,
                backgroundColor: context.colors.surface,
                side: BorderSide(
                  color: sel ? context.colors.primary : context.colors.border,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
            border: Border.all(color: context.colors.border),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start time',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(slotTime.format(context),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                  fontSize: 16,
                )),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.access_time, color: context.colors.primary, size: 20),
            ),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: slotTime);
              if (t != null) onTimeChanged(t);
            },
          ),
        ),
        const SizedBox(height: 20),
        Text('Duration',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: durations.map((d) {
            final sel = duration == d;
            return ChoiceChip(
              label: Text('$d min'),
              selected: sel,
              onSelected: (s) {
                if (s) onDurationChanged(d);
              },
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? context.colors.surface : context.colors.textPrimary,
              ),
              selectedColor: context.colors.primary,
              backgroundColor: context.colors.surface,
              side: BorderSide(
                color: sel ? context.colors.primary : context.colors.border,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Break after slot',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: breaks.map((m) {
            final sel = breakAfter == m;
            return ChoiceChip(
              label: Text(m == 0 ? 'None' : '$m min'),
              selected: sel,
              onSelected: (s) {
                if (s) onBreakChanged(m);
              },
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? context.colors.surface : context.colors.textPrimary,
              ),
              selectedColor: context.colors.primary,
              backgroundColor: context.colors.surface,
              side: BorderSide(
                color: sel ? context.colors.primary : context.colors.border,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.videocam_outlined, size: 18),
          const SizedBox(width: 8),
          Text('Online meeting',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Switch(value: isOnline, onChanged: onOnlineChanged),
        ]),
        if (isOnline) ...[
          const SizedBox(height: 12),
          TextFormField(
            initialValue: meetingLink,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Meeting link',
              hintText: 'https://meet.google.com/...',
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                borderSide: BorderSide(color: context.colors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: onLinkChanged,
          ),
        ],
      ],
    );
  }
}

// ─── Step 2: Batch review ─────────────────────────────────────────────────────

class _BatchStep extends StatelessWidget {
  final List<_SlotDraft> batch;
  final DateTime weekSunday;
  final bool Function(DateTime, int) hasExistingClash;
  final bool Function(_SlotDraft, DateTime) hasBatchClash;
  final DateTime Function(_SlotDraft) draftStart;
  final ValueChanged<_SlotDraft> onRemove;
  final VoidCallback onAddMore;
  const _BatchStep({
    super.key,
    required this.batch,
    required this.weekSunday,
    required this.hasExistingClash,
    required this.hasBatchClash,
    required this.draftStart,
    required this.onRemove,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    if (batch.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.inbox_outlined, size: 48, color: context.colors.border),
          const SizedBox(height: 12),
          Text('No slots in batch yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  )),
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${batch.length} slot${batch.length == 1 ? '' : 's'} queued',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 10),
        ...batch.map((d) {
          final start = draftStart(d);
          final end = start.add(Duration(minutes: d.durationMinutes));
          final clash = hasExistingClash(start, d.durationMinutes) || hasBatchClash(d, start);
          final timeLabel =
              '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} – '
              '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: clash
                  ? const Color(0xFFFEF2F2)
                  : context.colors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
              border: Border.all(
                color: clash ? const Color(0xFFFCA5A5) : context.colors.primaryLight,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${dayShortNamesSunFirst[d.dayIndex]}  $timeLabel · ${d.durationMinutes} min',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: clash ? const Color(0xFFDC2626) : context.colors.textPrimary,
                        ),
                  ),
                  if (d.breakAfterMinutes > 0 || d.isOnline)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          if (d.breakAfterMinutes > 0) '+${d.breakAfterMinutes}m break',
                          if (d.isOnline) 'Online',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (clash)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('⚠ Overlaps with existing slot',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              )),
                    ),
                ]),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onRemove(d),
              ),
            ]),
          );
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onAddMore,
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text('Add more slots'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step actions bar ─────────────────────────────────────────────────────────

class _StepActions extends StatelessWidget {
  final _Step step;
  final int batchCount;
  final int addableCount;
  final VoidCallback onAddToBatch;
  final VoidCallback onGoToReview;
  final VoidCallback onGoToConfigure;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _StepActions({
    required this.step,
    required this.batchCount,
    required this.addableCount,
    required this.onAddToBatch,
    required this.onGoToReview,
    required this.onGoToConfigure,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (step == _Step.configure) {
      return Row(children: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        const Spacer(),
        if (batchCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: onGoToReview,
              child: Text('Review ($batchCount)'),
            ),
          ),
        FilledButton.icon(
          onPressed: onAddToBatch,
          icon: const Icon(Icons.add, size: 18),
          label: Text(batchCount == 0 ? 'Add to batch' : 'Add another'),
        ),
      ]);
    }

    // Review step
    return Row(children: [
      TextButton(onPressed: onCancel, child: const Text('Cancel')),
      const Spacer(),
      FilledButton(
        onPressed: addableCount == 0 ? null : onConfirm,
        child: Text('Confirm $addableCount slot${addableCount == 1 ? '' : 's'}'),
      ),
    ]);
  }
}
