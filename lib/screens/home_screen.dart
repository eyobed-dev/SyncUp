import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../models/meeting.dart';
import '../data/backend_seed.dart';
import '../data/sample_data.dart';
import '../widgets/slots_view.dart';
import '../widgets/all_meetings_tab.dart';
import '../widgets/current_meeting_card.dart';
import '../widgets/dismissed_meeting_button.dart';
import '../widgets/syncup_logo.dart';
import '../widgets/user_profile_drawer.dart';
import '../utils/week_calendar.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _weekStart;
  late ValueNotifier<int> _selectedDayIndex;

  /// Drives live UI (current meeting, time line) without rebuilding the whole screen.
  late final ValueNotifier<DateTime> _clock;

  /// Grid slot size — updated by pinch or settings without rebuilding [HomeScreen].
  late final ValueNotifier<int> _slotDurationMinutes;
  int? _expandedDayIndex;
  Set<String> _dismissedMeetingIds = {};
  Set<String> _hiddenInProgressMeetingIds = {};
  Timer? _currentMeetingTimer;

  /// User-created slots for any week (filtered by visible week when merging).
  final List<Meeting> _extraMeetings = [];

  /// Hidden occurrences (postponed). Recurring meeting ids repeat each week, so key encodes date + id.
  final Set<String> _hiddenOccurrenceKeys = {};

  DateTime get _weekSunday => startOfWeekSunday(
    DateTime(_weekStart.year, _weekStart.month, _weekStart.day),
  );

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // Only to pass tickClock / liveClock to the active tab.
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _weekStart = DateTime.now();
    _selectedDayIndex = ValueNotifier(DateTime.now().weekday % 7);
    _clock = ValueNotifier(DateTime.now());
    _slotDurationMinutes = ValueNotifier(15);
    _currentMeetingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _clock.value = DateTime.now();
    });
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
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
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

  /// Demo current user (schedule owner) id.
  static const String _currentOwnerId = 'p1';

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

    final availability = BackendSeed.instance
        .availabilityForOwner(_currentOwnerId, _weekStart)
        .where((s) {
          final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
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

  Meeting? get _currentMeeting {
    final m = getCurrentMeetingFromList(_mergedMeetingsForWeek());
    if (m == null) return null;
    if (_dismissedMeetingIds.contains(m.id)) return null;
    if (_hiddenInProgressMeetingIds.contains(m.id)) return null;
    return m;
  }

  /// Current meeting that was dismissed – show restore button.
  Meeting? get _dismissedCurrentMeeting {
    final m = getCurrentMeetingFromList(_mergedMeetingsForWeek());
    if (m == null) return null;
    if (!_dismissedMeetingIds.contains(m.id)) return null;
    if (_hiddenInProgressMeetingIds.contains(m.id)) return null;
    return m;
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
      _dismissedMeetingIds.removeWhere((id) => meetingIds.contains(id));
      _hiddenInProgressMeetingIds.removeWhere((id) => meetingIds.contains(id));
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
    var dayIndex = _selectedDayIndex.value.clamp(0, 6);
    var duration = _slotDurationMinutes.value;
    if (!durations.contains(duration)) {
      duration = 30;
    }
    var slotTime = _defaultSlotTimeForAdd(
      dayIndex: dayIndex,
      durationMinutes: duration,
      addFromBottom: addFromBottom,
    );

    final weekSunday = _weekSunday;
    final availability = BackendSeed.instance.availabilityForOwner(
      _currentOwnerId,
      _weekStart,
    );
    final sundayDate = DateTime(weekSunday.year, weekSunday.month, weekSunday.day);
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    bool overlaps(DateTime aStart, int aMinutes, DateTime bStart, int bMinutes) {
      final aEnd = aStart.add(Duration(minutes: aMinutes));
      final bEnd = bStart.add(Duration(minutes: bMinutes));
      return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
    }

    List<Meeting> overlapsWithExisting(DateTime start, int durationMinutes) {
      final list = _mergedMeetingsForWeek();
      return list
          .where((m) => sameDay(m.startTime, start))
          .where((m) => overlaps(start, durationMinutes, m.startTime, m.durationMinutes))
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
        location: (location ?? '').trim().isEmpty ? 'Room LL4' : location!.trim(),
      );
    }

    Meeting meetingFromCustom({
      required DateTime startTime,
      required int durationMinutes,
    }) {
      return Meeting(
        id: 'extra-${DateTime.now().millisecondsSinceEpoch}-${startTime.microsecondsSinceEpoch}',
        participantName: 'Open slot',
        startTime: startTime,
        durationMinutes: durationMinutes,
        location: 'Room LL4',
      );
    }

    final selectedAvailabilityIds = <String>{};
    final customBatch = <({TimeOfDay time, int durationMinutes, int dayIndex})>[];

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
                availability.where((s) => sameDay(s.startTime, dayDate)).toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

            int countAddableSelected() {
              var n = 0;
              for (final s in dayAvailability) {
                if (!selectedAvailabilityIds.contains(s.id)) continue;
                if (overlapsWithExisting(s.startTime, s.durationMinutes).isNotEmpty) continue;
                n++;
              }
              for (final c in customBatch) {
                final d = sundayDate.add(Duration(days: c.dayIndex));
                final start = DateTime(d.year, d.month, d.day, c.time.hour, c.time.minute);
                if (overlapsWithExisting(start, c.durationMinutes).isNotEmpty) continue;
                // also check overlaps within the custom batch itself
                var clashesInBatch = false;
                for (final other in customBatch) {
                  if (identical(other, c)) continue;
                  final od = sundayDate.add(Duration(days: other.dayIndex));
                  final ostart =
                      DateTime(od.year, od.month, od.day, other.time.hour, other.time.minute);
                  if (sameDay(ostart, start) &&
                      overlaps(start, c.durationMinutes, ostart, other.durationMinutes)) {
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
                _mergedMeetingsForWeek().where((m) => sameDay(m.startTime, dayDate)).where((m) {
                  return m.participantName.trim().toLowerCase() == 'open slot';
                }).toList()
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
                    FilledButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          customBatch.add((time: slotTime, durationMinutes: duration, dayIndex: dayIndex));
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        customBatch.isEmpty ? 'Add this slot to batch' : 'Add another',
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                        final start = DateTime(d.year, d.month, d.day, c.time.hour, c.time.minute);
                        final end = start.add(Duration(minutes: c.durationMinutes));
                        final existingClashes = overlapsWithExisting(start, c.durationMinutes);
                        var batchClashCount = 0;
                        for (final other in customBatch) {
                          if (identical(other, c)) continue;
                          final od = sundayDate.add(Duration(days: other.dayIndex));
                          final ostart =
                              DateTime(od.year, od.month, od.day, other.time.hour, other.time.minute);
                          if (sameDay(ostart, start) &&
                              overlaps(start, c.durationMinutes, ostart, other.durationMinutes)) {
                            batchClashCount++;
                          }
                        }
                        final hasClash = existingClashes.isNotEmpty || batchClashCount > 0;
                        final timeLabel =
                            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} – ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${dayShortNamesSunFirst[c.dayIndex]} · $timeLabel · ${c.durationMinutes} min',
                                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                        color: hasClash ? const Color(0xFFDC2626) : SyncUpTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              if (hasClash)
                                Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Tooltip(
                                    message: [
                                      if (existingClashes.isNotEmpty) 'Overlaps with existing slot(s)',
                                      if (batchClashCount > 0) 'Overlaps with $batchClashCount in this batch',
                                    ].join(' · '),
                                    child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
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
                      'Available (Prof. Alexander) · not yet picked',
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SyncUpTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    if (dayAvailability.isEmpty)
                      Text(
                        'No availability seeded for ${dayShortNamesSunFirst[dayIndex]}.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: SyncUpTheme.textSecondary,
                            ),
                      )
                    else
                      ...dayAvailability.map((s) {
                        final clashes = overlapsWithExisting(s.startTime, s.durationMinutes);
                        final taken = clashes.isNotEmpty;
                        final end = s.startTime.add(Duration(minutes: s.durationMinutes));
                        final timeLabel =
                            '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')} – ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: selectedAvailabilityIds.contains(s.id),
                          onChanged: taken
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
                                  color: taken ? SyncUpTheme.textSecondary : SyncUpTheme.textPrimary,
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
                      if (overlapsWithExisting(s.startTime, s.durationMinutes).isNotEmpty) continue;
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
                      final start = DateTime(d.year, d.month, d.day, c.time.hour, c.time.minute);
                      if (overlapsWithExisting(start, c.durationMinutes).isNotEmpty) continue;
                      var clashesInBatch = false;
                      for (final other in customBatch) {
                        if (identical(other, c)) continue;
                        final od = sundayDate.add(Duration(days: other.dayIndex));
                        final ostart =
                            DateTime(od.year, od.month, od.day, other.time.hour, other.time.minute);
                        if (sameDay(ostart, start) &&
                            overlaps(start, c.durationMinutes, ostart, other.durationMinutes)) {
                          clashesInBatch = true;
                          break;
                        }
                      }
                      if (clashesInBatch) continue;
                      out.add(
                        meetingFromCustom(startTime: start, durationMinutes: c.durationMinutes),
                      );
                    }

                    Navigator.of(ctx).pop(out);
                  },
                  child: Text(
                    'Add ${countAddableSelected()}',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (toAdd == null || toAdd.isEmpty || !mounted) return;
    setState(() => _extraMeetings.addAll(toAdd));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${toAdd.length} slot(s) added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _expandedDayIndex = null;
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _expandedDayIndex = null;
    });
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
                      child: const Text(
                        'M',
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
      endDrawer: UserProfileDrawer(onSettingsTap: _openSettings),
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
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Meetings'), Tab(text: 'Calendar')],
          ),
          ValueListenableBuilder<DateTime>(
            valueListenable: _clock,
            builder: (context, _, __) {
              final current = _currentMeeting;
              final dismissed = _dismissedCurrentMeeting;
              // Do not use [Flexible] here: it would split space 50/50 with [TabBarView]
              // and shrink the calendar. Shrink-wrapped list keeps banner height intrinsic.
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                // Default uses StackFit.passthrough + center alignment, which can let
                // the banner subtree expand to the full column height above the tab body.
                layoutBuilder: (
                  Widget? currentChild,
                  List<Widget> previousChildren,
                ) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    fit: StackFit.loose,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(curved),
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.97,
                          end: 1,
                        ).animate(curved),
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _MeetingBannerSlot(
                  key: ValueKey<String>(
                    current != null
                        ? 'current-${current.id}'
                        : dismissed != null
                        ? 'dismissed-${dismissed.id}'
                        : 'empty',
                  ),
                  current: current,
                  dismissed: dismissed,
                  onDismissMeeting: (id) {
                    setState(() => _dismissedMeetingIds.add(id));
                  },
                  onRestoreMeeting: (id) {
                    setState(() => _dismissedMeetingIds.remove(id));
                  },
                  onHideInProgress: (id) {
                    setState(() {
                      _hiddenInProgressMeetingIds.add(id);
                      _dismissedMeetingIds.remove(id);
                    });
                  },
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AllMeetingsTab(
                  weekStart: _weekStart,
                  meetings: _mergedMeetingsForWeek(),
                  selectedDayIndex: _selectedDayIndex,
                  liveClock: _tabController.index == 0 ? _clock : null,
                  onAddSlot:
                      (fromBottom) =>
                          _showAddSlotDialog(addFromBottom: fromBottom),
                  onBulkPostpone: _onBulkPostpone,
                  onRemoveNewSlots: _removeNewSlots,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: SlotsView(
                    key: ValueKey(_expandedDayIndex ?? -1),
                    weekStart: _weekStart,
                    slotDuration: _slotDurationMinutes,
                    meetings: _mergedMeetingsForWeek(),
                    expandedDayIndex: _expandedDayIndex,
                    onDayTap: (i) => setState(() => _expandedDayIndex = i),
                    onBack: () => setState(() => _expandedDayIndex = null),
                    tickClock: _tabController.index == 1 ? _clock : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner under the tab bar: shrink-wrapped so [Expanded] below keeps full height.
/// Keys drive [AnimatedSwitcher] when in-progress / dismissed / hidden changes.
class _MeetingBannerSlot extends StatelessWidget {
  final Meeting? current;
  final Meeting? dismissed;
  final ValueChanged<String> onDismissMeeting;
  final ValueChanged<String> onRestoreMeeting;
  final ValueChanged<String> onHideInProgress;

  const _MeetingBannerSlot({
    super.key,
    required this.current,
    required this.dismissed,
    required this.onDismissMeeting,
    required this.onRestoreMeeting,
    required this.onHideInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    // Cap banner height so TabBarView always gets the rest of the screen; scroll inside if needed.
    final maxBannerH = (h * 0.34).clamp(120.0, 320.0);

    if (current != null) {
      final m = current!;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxBannerH),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: CurrentMeetingCard(
            meeting: m,
            accentColor: SyncUpTheme.primary,
            onMissed: () {
              // Record missed – card stays visible
            },
            onOntime: () {
              // Record ontime – card stays visible
            },
            onLate: () {
              // Record late – card stays visible
            },
            onDismiss: () => onDismissMeeting(m.id),
          ),
        ),
      );
    }
    if (dismissed != null) {
      final m = dismissed!;
      return DismissedMeetingButton(
        meeting: m,
        onTap: () => onRestoreMeeting(m.id),
        onDismissAll: () => onHideInProgress(m.id),
      );
    }
    return const SizedBox.shrink();
  }
}
