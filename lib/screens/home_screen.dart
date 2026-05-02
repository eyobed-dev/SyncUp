import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../models/availability_slot.dart';
import '../models/meeting.dart';
import '../data/live_backend_cache.dart';
import '../data/sample_data.dart';
import '../data/availability_data.dart';
import '../widgets/all_meetings_tab.dart';
import '../widgets/syncup_logo.dart';
import '../widgets/user_profile_drawer.dart';
import '../utils/week_calendar.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.ownerId,
    required this.displayName,
    required this.username,
    required this.roleLabel,
    required this.userId,
    this.onSignOut,
  });

  final String ownerId;
  final String displayName;
  final String username;
  final String roleLabel;
  final String userId;
  final VoidCallback? onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _weekStart;
  late ValueNotifier<int> _selectedDayIndex;

  /// Drives live UI (current meeting, time line) without rebuilding the whole screen.
  late final ValueNotifier<DateTime> _clock;

  /// Grid slot size — updated by pinch or settings without rebuilding [HomeScreen].
  late final ValueNotifier<int> _slotDurationMinutes;
  Timer? _currentMeetingTimer;
  bool _isSyncingWeek = false;

  /// User-created slots for any week (filtered by visible week when merging).
  final List<Meeting> _extraMeetings = [];

  /// Hidden occurrences (postponed). Recurring meeting ids repeat each week, so key encodes date + id.
  final Set<String> _hiddenOccurrenceKeys = {};

  DateTime get _weekSunday => startOfWeekSunday(
    DateTime(_weekStart.year, _weekStart.month, _weekStart.day),
  );

  @override
  void initState() {
    super.initState();
    _weekStart = startOfWeekSunday(DateTime.now());
    _selectedDayIndex = ValueNotifier(DateTime.now().weekday % 7);
    _clock = ValueNotifier(DateTime.now());
    _slotDurationMinutes = ValueNotifier(15);
    _currentMeetingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _clock.value = DateTime.now();
    });
    _syncWeekData();
  }

  Future<void> _syncWeekData() async {
    setState(() => _isSyncingWeek = true);
    final weekAnchor = _weekSunday;
    try {
      await syncMeetingsForWeek(
        weekAnchor,
        ownerId: widget.ownerId,
      );
      await syncAvailabilityForOwner(widget.ownerId, weekAnchor);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load meetings for this week'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncingWeek = false);
    }
  }

  Future<void> _submitMeetingStatus(Meeting meeting, String status) async {
    try {
      await LiveBackendCache.instance.updateMeetingStatus(
        ownerId: widget.ownerId,
        meeting: meeting,
        status: status,
      );
      await syncMeetingsForWeek(
        _weekSunday,
        ownerId: widget.ownerId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meeting marked as ${status.toUpperCase()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update meeting status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openSettings() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              slotDurationMinutes: _slotDurationMinutes.value,
              onSlotDurationChanged: (v) => _slotDurationMinutes.value = v,
            ),
      ),
    );
    if (result != null) {
      _slotDurationMinutes.value = result;
    }
  }

  @override
  void dispose() {
    _currentMeetingTimer?.cancel();
    _selectedDayIndex.dispose();
    _clock.dispose();
    _slotDurationMinutes.dispose();
    super.dispose();
  }

  String _occurrenceKey(Meeting m) {
    if (m.id.startsWith('extra-')) return m.id;
    if (m.id.startsWith('open-')) return m.id;
    final d = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
    return '${d.year}-${d.month}-${d.day}:${m.id}';
  }

  Meeting _openSlotFromAvailability({
    required String slotId,
    required DateTime startTime,
    required int durationMinutes,
    String? location,
  }) {
    final dateKey =
        '${startTime.year}${startTime.month.toString().padLeft(2, '0')}${startTime.day.toString().padLeft(2, '0')}';
    return Meeting(
      id: 'open-$slotId-$dateKey',
      participantName: 'Open slot',
      startTime: startTime,
      durationMinutes: durationMinutes,
      location: (location ?? '').trim().isEmpty ? 'Room LL4' : location!.trim(),
    );
  }

  List<Meeting> _mergedMeetingsForWeek() {
    final sun = _weekSunday;
    final weekStartDate = DateTime(sun.year, sun.month, sun.day);
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    bool inWeek(Meeting m) {
      final d = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
      return !d.isBefore(weekStartDate) && !d.isAfter(weekEndDate);
    }

    final weekly = getMeetingsForWeek(
      _weekStart,
    ).where((m) => !_hiddenOccurrenceKeys.contains(_occurrenceKey(m)));
    final extra = _extraMeetings
        .where((m) => !_hiddenOccurrenceKeys.contains(_occurrenceKey(m)))
        .where(inWeek);

    final taken = <String>{};
    for (final m in [...weekly, ...extra]) {
      final key = '${m.startTime.toIso8601String()}|${m.durationMinutes}';
      taken.add(key);
    }

    final availability = getAvailabilityForOwner(widget.ownerId, _weekStart)
        .where((s) {
          final d = DateTime(
            s.startTime.year,
            s.startTime.month,
            s.startTime.day,
          );
          return !d.isBefore(weekStartDate) && !d.isAfter(weekEndDate);
        })
        .where((s) {
          final key = '${s.startTime.toIso8601String()}|${s.durationMinutes}';
          return !taken.contains(key);
        })
        .map(
          (s) => _openSlotFromAvailability(
            slotId: s.id,
            startTime: s.startTime,
            durationMinutes: s.durationMinutes,
            location: s.location,
          ),
        )
        .where((m) => !_hiddenOccurrenceKeys.contains(_occurrenceKey(m)));

    final all = [...weekly, ...extra, ...availability]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return all;
  }

  void _onBulkPostpone(Set<String> meetingIds, String apologyMessage) {
    final list = _mergedMeetingsForWeek();
    setState(() {
      for (final id in meetingIds) {
        for (final m in list) {
          if (m.id == id) {
            _hiddenOccurrenceKeys.add(_occurrenceKey(m));
            break;
          }
        }
      }
    });
    debugPrint('Postpone apology (demo): $apologyMessage');
  }

  void _removeNewSlots(Set<String> meetingIds) {
    setState(() {
      _extraMeetings.removeWhere((m) => meetingIds.contains(m.id));
      // Extra occurrence keys are the ids themselves.
      _hiddenOccurrenceKeys.removeWhere((k) => meetingIds.contains(k));
    });
  }

  List<Meeting> _meetingsForDayIndex(int dayIndex) {
    final weekSunday = _weekSunday;
    final day = weekSunday.add(Duration(days: dayIndex));
    return _mergedMeetingsForWeek().where((m) {
        final md = DateTime(
          m.startTime.year,
          m.startTime.month,
          m.startTime.day,
        );
        final dd = DateTime(day.year, day.month, day.day);
        return md == dd;
      }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<AvailabilitySlot> _toAvailabilitySlots(List<Meeting> meetings) {
    return meetings
        .where((m) => m.id.startsWith('extra-'))
        .map((m) {
          final rawLocation = (m.location ?? '').trim();
          String? location;
          String? meetingLink;
          if (rawLocation.toLowerCase().startsWith('online')) {
            final parts = rawLocation.split('•');
            if (parts.length > 1) {
              final link = parts.sublist(1).join('•').trim();
              if (link.isNotEmpty) meetingLink = link;
            }
          } else if (rawLocation.isNotEmpty) {
            location = rawLocation;
          }
          return AvailabilitySlot(
            id: m.id,
            startTime: m.startTime,
            durationMinutes: m.durationMinutes,
            title: 'Open slot',
            location: location,
            meetingLink: meetingLink,
          );
        })
        .toList();
  }

  /// [addFromBottom]: top button = work backward from last meeting; bottom = forward from last end.
  TimeOfDay _defaultSlotTimeForAdd({
    required int dayIndex,
    required int durationMinutes,
    required bool addFromBottom,
  }) {
    final list = _meetingsForDayIndex(dayIndex);
    if (list.isEmpty) {
      if (addFromBottom) {
        return const TimeOfDay(hour: 8, minute: 0);
      }
      return const TimeOfDay(hour: 17, minute: 0);
    }
    final last = list.last;
    if (addFromBottom) {
      return TimeOfDay.fromDateTime(last.endTime);
    }
    final proposedStart = last.startTime.subtract(
      Duration(minutes: durationMinutes),
    );
    final dayStart = DateTime(
      last.startTime.year,
      last.startTime.month,
      last.startTime.day,
      8,
      0,
    );
    if (proposedStart.isBefore(dayStart)) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
    return TimeOfDay.fromDateTime(proposedStart);
  }

  Future<void> _showAddSlotDialog({required bool addFromBottom}) async {
    const durations = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];
    const breakOptions = [0, 5, 10, 15, 20, 30, 45, 60];
    var dayIndex = _selectedDayIndex.value.clamp(0, 6);
    var duration = _slotDurationMinutes.value;
    var breakBetweenSlotsMinutes = 0;
    var customIsOnline = false;
    var customMeetingLink = '';
    if (!durations.contains(duration)) {
      duration = 30;
    }
    var slotTime = _defaultSlotTimeForAdd(
      dayIndex: dayIndex,
      durationMinutes: duration,
      addFromBottom: addFromBottom,
    );

    final weekSunday = _weekSunday;
    final availability = getAvailabilityForOwner(widget.ownerId, _weekStart);
    final sundayDate = DateTime(
      weekSunday.year,
      weekSunday.month,
      weekSunday.day,
    );
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    bool overlaps(
      DateTime aStart,
      int aMinutes,
      DateTime bStart,
      int bMinutes,
    ) {
      final aEnd = aStart.add(Duration(minutes: aMinutes));
      final bEnd = bStart.add(Duration(minutes: bMinutes));
      return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
    }

    List<Meeting> overlapsWithExisting(DateTime start, int durationMinutes) {
      final list = _mergedMeetingsForWeek();
      return list
          .where((m) => sameDay(m.startTime, start))
          .where(
            (m) => overlaps(
              start,
              durationMinutes,
              m.startTime,
              m.durationMinutes,
            ),
          )
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    Meeting meetingFromAvailability({
      required String slotId,
      required DateTime startTime,
      required int durationMinutes,
      String? location,
    }) {
      final dateKey =
          '${startTime.year}${startTime.month.toString().padLeft(2, '0')}${startTime.day.toString().padLeft(2, '0')}';
      return Meeting(
        id: 'open-$slotId-$dateKey',
        participantName: 'Open slot',
        startTime: startTime,
        durationMinutes: durationMinutes,
        location:
            (location ?? '').trim().isEmpty ? 'Room LL4' : location!.trim(),
      );
    }

    Meeting meetingFromCustom({
      required DateTime startTime,
      required int durationMinutes,
      required bool isOnline,
      String? meetingLink,
    }) {
      final link = (meetingLink ?? '').trim();
      return Meeting(
        id:
            'extra-${DateTime.now().millisecondsSinceEpoch}-${startTime.microsecondsSinceEpoch}',
        participantName: 'Open slot',
        startTime: startTime,
        durationMinutes: durationMinutes,
        location: isOnline
            ? (link.isEmpty ? 'Online' : 'Online • $link')
            : 'Room LL4',
      );
    }

    final selectedAvailabilityIds = <String>{};
    final customBatch =
        <({
          TimeOfDay time,
          int durationMinutes,
          int dayIndex,
          int breakAfterMinutes,
          bool isOnline,
          String meetingLink,
        })>[];

    final toAdd = await showDialog<List<Meeting>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void applyDayOrDurationChange() {
              slotTime = _defaultSlotTimeForAdd(
                dayIndex: dayIndex,
                durationMinutes: duration,
                addFromBottom: addFromBottom,
              );
            }

            final dayDate = sundayDate.add(Duration(days: dayIndex));
            final dayAvailability =
                availability
                    .where((s) => sameDay(s.startTime, dayDate))
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

            int countAddableSelected() {
              var n = 0;
              for (final s in dayAvailability) {
                if (!selectedAvailabilityIds.contains(s.id)) continue;
                if (overlapsWithExisting(
                  s.startTime,
                  s.durationMinutes,
                ).isNotEmpty)
                  continue;
                n++;
              }
              for (final c in customBatch) {
                final d = sundayDate.add(Duration(days: c.dayIndex));
                final start = DateTime(
                  d.year,
                  d.month,
                  d.day,
                  c.time.hour,
                  c.time.minute,
                );
                if (overlapsWithExisting(start, c.durationMinutes).isNotEmpty)
                  continue;
                // also check overlaps within the custom batch itself
                var clashesInBatch = false;
                for (final other in customBatch) {
                  if (identical(other, c)) continue;
                  final od = sundayDate.add(Duration(days: other.dayIndex));
                  final ostart = DateTime(
                    od.year,
                    od.month,
                    od.day,
                    other.time.hour,
                    other.time.minute,
                  );
                  if (sameDay(ostart, start) &&
                      overlaps(
                        start,
                        c.durationMinutes,
                        ostart,
                        other.durationMinutes,
                      )) {
                    clashesInBatch = true;
                    break;
                  }
                }
                if (clashesInBatch) continue;
                n++;
              }
              return n;
            }

            final openSlotsToday =
                _mergedMeetingsForWeek()
                    .where((m) => sameDay(m.startTime, dayDate))
                    .where((m) {
                      return m.participantName.trim().toLowerCase() ==
                          'open slot';
                    })
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

            return AlertDialog(
              title: const Text('Add slots'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      addFromBottom
                          ? 'Default time starts after the last meeting of the day (or 8:00 if none).'
                          : 'Default time sits before the last meeting of the day (or 17:00 if none).',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: SyncUpTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: dayIndex,
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        7,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(dayShortNamesSunFirst[i]),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            dayIndex = v;
                            applyDayOrDurationChange();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start time'),
                      subtitle: Text(slotTime.format(ctx)),
                      trailing: const Icon(Icons.schedule),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: slotTime,
                        );
                        if (t != null) setDialogState(() => slotTime = t);
                      },
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: duration,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          durations
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text('$d min'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            duration = v;
                            if (!addFromBottom) {
                              applyDayOrDurationChange();
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: breakBetweenSlotsMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Break after slot',
                        border: OutlineInputBorder(),
                      ),
                      items: breakOptions
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m == 0 ? 'No break' : '$m min'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => breakBetweenSlotsMinutes = v);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.videocam_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Online meeting',
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: SyncUpTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: customIsOnline,
                          onChanged: (v) {
                            setDialogState(() => customIsOnline = v);
                          },
                        ),
                      ],
                    ),
                    if (customIsOnline) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: customMeetingLink,
                        decoration: const InputDecoration(
                          labelText: 'Meeting link',
                          hintText: 'https://meet.google.com/...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          customMeetingLink = v;
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () {
                        if (customIsOnline &&
                            customMeetingLink.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please add a meeting link for online slots.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        setDialogState(() {
                          customBatch.add((
                            time: slotTime,
                            durationMinutes: duration,
                            dayIndex: dayIndex,
                            breakAfterMinutes: breakBetweenSlotsMinutes,
                            isOnline: customIsOnline,
                            meetingLink: customMeetingLink.trim(),
                          ));
                          final nextTime = DateTime(
                            2000,
                            1,
                            1,
                            slotTime.hour,
                            slotTime.minute,
                          ).add(
                            Duration(
                              minutes: duration + breakBetweenSlotsMinutes,
                            ),
                          );
                          slotTime = TimeOfDay(
                            hour: nextTime.hour % 24,
                            minute: nextTime.minute,
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        customBatch.isEmpty
                            ? 'Add this slot to batch'
                            : 'Add another',
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    if (customBatch.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Batch (${customBatch.length})',
                        style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SyncUpTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...customBatch.map((c) {
                        final d = sundayDate.add(Duration(days: c.dayIndex));
                        final start = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          c.time.hour,
                          c.time.minute,
                        );
                        final end = start.add(
                          Duration(minutes: c.durationMinutes),
                        );
                        final existingClashes = overlapsWithExisting(
                          start,
                          c.durationMinutes,
                        );
                        var batchClashCount = 0;
                        for (final other in customBatch) {
                          if (identical(other, c)) continue;
                          final od = sundayDate.add(
                            Duration(days: other.dayIndex),
                          );
                          final ostart = DateTime(
                            od.year,
                            od.month,
                            od.day,
                            other.time.hour,
                            other.time.minute,
                          );
                          if (sameDay(ostart, start) &&
                              overlaps(
                                start,
                                c.durationMinutes,
                                ostart,
                                other.durationMinutes,
                              )) {
                            batchClashCount++;
                          }
                        }
                        final hasClash =
                            existingClashes.isNotEmpty || batchClashCount > 0;
                        final timeLabel =
                            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} – ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${dayShortNamesSunFirst[c.dayIndex]} · $timeLabel · ${c.durationMinutes} min'
                                  '${c.breakAfterMinutes > 0 ? ' · +${c.breakAfterMinutes}m break' : ''}'
                                  '${c.isOnline ? ' · online' : ''}',
                                  style: Theme.of(
                                    ctx,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        hasClash
                                            ? const Color(0xFFDC2626)
                                            : SyncUpTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (hasClash)
                                Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Tooltip(
                                    message: [
                                      if (existingClashes.isNotEmpty)
                                        'Overlaps with existing slot(s)',
                                      if (batchClashCount > 0)
                                        'Overlaps with $batchClashCount in this batch',
                                    ].join(' · '),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: () {
                                  setDialogState(() {
                                    customBatch.remove(c);
                                  });
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Available slots · not yet picked',
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SyncUpTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (dayAvailability.isEmpty)
                      Text(
                        'No availability for ${dayShortNamesSunFirst[dayIndex]}.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: SyncUpTheme.textSecondary,
                        ),
                      )
                    else
                      ...dayAvailability.map((s) {
                        final clashes = overlapsWithExisting(
                          s.startTime,
                          s.durationMinutes,
                        );
                        final taken = clashes.isNotEmpty;
                        final end = s.startTime.add(
                          Duration(minutes: s.durationMinutes),
                        );
                        final timeLabel =
                            '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')} – ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: selectedAvailabilityIds.contains(s.id),
                          onChanged:
                              taken
                                  ? null
                                  : (v) {
                                    setDialogState(() {
                                      if (v == true) {
                                        selectedAvailabilityIds.add(s.id);
                                      } else {
                                        selectedAvailabilityIds.remove(s.id);
                                      }
                                    });
                                  },
                          title: Text(
                            timeLabel,
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  taken
                                      ? SyncUpTheme.textSecondary
                                      : SyncUpTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            taken
                                ? 'Overlaps with existing meeting'
                                : (s.location ?? 'Room LL4'),
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: SyncUpTheme.textSecondary,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }),
                    if (openSlotsToday.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Open slots already on this day (${openSlotsToday.length})',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: SyncUpTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(const <Meeting>[]),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final out = <Meeting>[];

                    // Selected availability → open slots
                    for (final s in dayAvailability) {
                      if (!selectedAvailabilityIds.contains(s.id)) continue;
                      if (overlapsWithExisting(
                        s.startTime,
                        s.durationMinutes,
                      ).isNotEmpty)
                        continue;
                      out.add(
                        meetingFromAvailability(
                          slotId: s.id,
                          startTime: s.startTime,
                          durationMinutes: s.durationMinutes,
                          location: s.location,
                        ),
                      );
                    }

                    // Custom batch → open slots
                    for (final c in customBatch) {
                      final d = sundayDate.add(Duration(days: c.dayIndex));
                      final start = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        c.time.hour,
                        c.time.minute,
                      );
                      if (overlapsWithExisting(
                        start,
                        c.durationMinutes,
                      ).isNotEmpty)
                        continue;
                      var clashesInBatch = false;
                      for (final other in customBatch) {
                        if (identical(other, c)) continue;
                        final od = sundayDate.add(
                          Duration(days: other.dayIndex),
                        );
                        final ostart = DateTime(
                          od.year,
                          od.month,
                          od.day,
                          other.time.hour,
                          other.time.minute,
                        );
                        if (sameDay(ostart, start) &&
                            overlaps(
                              start,
                              c.durationMinutes,
                              ostart,
                              other.durationMinutes,
                            )) {
                          clashesInBatch = true;
                          break;
                        }
                      }
                      if (clashesInBatch) continue;
                      out.add(
                        meetingFromCustom(
                          startTime: start,
                          durationMinutes: c.durationMinutes,
                          isOnline: c.isOnline,
                          meetingLink: c.meetingLink,
                        ),
                      );
                    }

                    Navigator.of(ctx).pop(out);
                  },
                  child: Text('Add ${countAddableSelected()}'),
                ),
              ],
            );
          },
        );
      },
    );

    if (toAdd == null || toAdd.isEmpty || !mounted) return;
    setState(() => _extraMeetings.addAll(toAdd));

    final slotsToPersist = _toAvailabilitySlots(toAdd);
    if (slotsToPersist.isNotEmpty) {
      LiveBackendCache.instance.upsertAvailabilitySlotsLocal(
        ownerId: widget.ownerId,
        slots: slotsToPersist,
      );
      try {
        await LiveBackendCache.instance.createAvailabilitySlots(
          ownerId: widget.ownerId,
          slots: slotsToPersist,
        );
        await syncAvailabilityForOwner(widget.ownerId, _weekStart);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally, but backend sync failed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${toAdd.length} schedule slot(s) added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    _syncWeekData();
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
    _syncWeekData();
  }

  String get _weekRange {
    final sat = _weekSunday.add(const Duration(days: 6));
    return '${_weekSunday.day}–${sat.day}';
  }

  String get _monthLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[_weekSunday.month - 1];
  }

  String get _weekLabel => '$_monthLabel $_weekRange ${_weekSunday.year}';

  /// Returns badge label for the displayed week: this week, past N week(s), or next N week(s).
  String get _weekBadgeLabel {
    final now = DateTime.now();
    final thisWeekSunday = startOfWeekSunday(
      DateTime(now.year, now.month, now.day),
    );
    final displayedSunday = DateTime(
      _weekSunday.year,
      _weekSunday.month,
      _weekSunday.day,
    );
    if (displayedSunday == thisWeekSunday) return 'This week';
    if (displayedSunday.isAfter(thisWeekSunday)) {
      final weeksAhead = displayedSunday.difference(thisWeekSunday).inDays ~/ 7;
      return 'Next ${weeksAhead} week${weeksAhead == 1 ? '' : 's'}';
    }
    final weeksAgo = thisWeekSunday.difference(displayedSunday).inDays ~/ 7;
    return 'Past ${weeksAgo} week${weeksAgo == 1 ? '' : 's'}';
  }

  Color get _weekBadgeColor {
    final now = DateTime.now();
    final thisWeekSunday = startOfWeekSunday(
      DateTime(now.year, now.month, now.day),
    );
    final displayedSunday = DateTime(
      _weekSunday.year,
      _weekSunday.month,
      _weekSunday.day,
    );
    if (displayedSunday == thisWeekSunday) return SyncUpTheme.primary;
    if (displayedSunday.isAfter(thisWeekSunday)) return Colors.blue.shade700;
    return SyncUpTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final compactAppBar = Responsive.isMobile(context);
    return Scaffold(
      appBar: AppBar(
        title: SyncUpLogo(size: 28, compact: compactAppBar),
        actions: [
          Builder(
            builder:
                (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: SyncUpTheme.primary,
                      child: Text(
                        widget.displayName.trim().isNotEmpty
                            ? widget.displayName.trim()[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
      endDrawer: UserProfileDrawer(
        displayName: widget.displayName,
        username: widget.username,
        email: widget.username.trim().toLowerCase().contains('@')
            ? widget.username.trim().toLowerCase()
            : '${widget.username.trim().toLowerCase()}@fit.cvut.cz',
        roleLabel: widget.roleLabel,
        userId: widget.userId,
        onSettingsTap: _openSettings,
        onSignOutTap: widget.onSignOut,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SyncUpTheme.surface,
              border: Border(bottom: BorderSide(color: SyncUpTheme.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevWeek,
                  tooltip: 'Previous week',
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _weekLabel,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: SyncUpTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _weekBadgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              SyncUpTheme.radiusXs,
                            ),
                            border: Border.all(
                              color: _weekBadgeColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _weekBadgeLabel,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: _weekBadgeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextWeek,
                  tooltip: 'Next week',
                ),
              ],
            ),
          ),
          if (_isSyncingWeek) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: AllMeetingsTab(
              weekStart: _weekStart,
              meetings: _mergedMeetingsForWeek(),
              selectedDayIndex: _selectedDayIndex,
              liveClock: _clock,
              onMeetingStatus: _submitMeetingStatus,
              onAddSlot:
                  (fromBottom) =>
                      _showAddSlotDialog(addFromBottom: fromBottom),
              onBulkPostpone: _onBulkPostpone,
              onRemoveNewSlots: _removeNewSlots,
            ),
          ),
        ],
      ),
    );
  }
}
