/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Primary application view for the home_screen.
 */

import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../models/availability_slot.dart';
import '../models/meeting.dart';
import '../data/live_backend_cache.dart';
import '../data/sample_data.dart';
import '../data/availability_data.dart';
import '../widgets/add_slot_sheet.dart';
import '../widgets/all_meetings_tab.dart';
import '../widgets/syncup_logo.dart';
import '../widgets/user_profile_drawer.dart';
import '../utils/week_calendar.dart';
import 'settings_screen.dart';
import 'package:sync_up/theme/sync_up_colors.dart';

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
    required String title,
    String? location,
  }) {
    final dateKey =
        '${startTime.year}${startTime.month.toString().padLeft(2, '0')}${startTime.day.toString().padLeft(2, '0')}';
    return Meeting(
      id: 'open-$slotId-$dateKey',
      participantName: 'Open slot',
      startTime: startTime,
      durationMinutes: durationMinutes,
      topic: title.trim().isEmpty ? null : title.trim(),
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
            title: s.title,
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
            title: (m.topic ?? '').trim().isEmpty ? 'Consultation' : m.topic!.trim(),
            location: location,
            meetingLink: meetingLink,
          );
        })
        .toList();
  }

  Future<void> _showAddSlotSheet() async {
    final toAdd = await showAddSlotSheet(
      context: context,
      ownerId: widget.ownerId,
      weekStart: _weekStart,
      initialDayIndex: _selectedDayIndex.value.clamp(0, 6),
      slotDurationMinutes: _slotDurationMinutes.value,
      existingMeetings: _mergedMeetingsForWeek(),
    );
    if (toAdd == null || toAdd.isEmpty || !mounted) return;
    setState(() => _extraMeetings.addAll(toAdd));

    final slotsToPersist = _toAvailabilitySlots(toAdd);
    if (slotsToPersist.isNotEmpty) {
      final persistedIds = slotsToPersist.map((s) => s.id).toSet();
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
      } catch (error) {
        if (!mounted) return;
        // Avoid showing local-only slots as persisted when backend save fails.
        setState(() {
          _extraMeetings.removeWhere((m) => persistedIds.contains(m.id));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save slots to backend: ${error.toString()}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
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

  bool get _isCurrentWeek {
    final todayWeek = startOfWeekSunday(DateTime.now());
    return _weekSunday == todayWeek;
  }

  void _goToToday() {
    final now = DateTime.now();
    final todayWeek = startOfWeekSunday(now);
    _selectedDayIndex.value = now.weekday % 7;
    if (_weekSunday == todayWeek) return;
    setState(() {
      _weekStart = todayWeek;
    });
    _syncWeekData();
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
                (context) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Scaffold.of(context).openEndDrawer(),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: context.colors.primary,
                      child: Text(
                        widget.displayName.trim().isNotEmpty
                            ? widget.displayName.trim()[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: context.colors.surface,
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
            : '${widget.username.trim().toLowerCase()}@fit.vut.cz',
        roleLabel: widget.roleLabel,
        userId: widget.userId,
        onSettingsTap: _openSettings,
        onSignOutTap: widget.onSignOut,
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -300) _nextWeek();
          if ((details.primaryVelocity ?? 0) > 300) _prevWeek();
        },
        child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(bottom: BorderSide(color: context.colors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevWeek,
                  tooltip: 'Previous week',
                ),
                TextButton.icon(
                  onPressed: _goToToday,
                  icon: Icon(
                    Icons.today_outlined,
                    size: 16,
                    color: _isCurrentWeek
                        ? context.colors.primary
                        : context.colors.surface,
                  ),
                  label: Text(
                    'Today',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _isCurrentWeek
                          ? context.colors.primary
                          : context.colors.surface,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: _isCurrentWeek
                        ? context.colors.primaryLight.withValues(alpha: 0.4)
                        : context.colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
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
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
          SizedBox(
            height: 2,
            child: Opacity(
              opacity: _isSyncingWeek ? 1.0 : 0.0,
              child: const LinearProgressIndicator(minHeight: 2),
            ),
          ),
          Expanded(
            child: AllMeetingsTab(
              weekStart: _weekStart,
              meetings: _mergedMeetingsForWeek(),
              selectedDayIndex: _selectedDayIndex,
              liveClock: _clock,
              onMeetingStatus: _submitMeetingStatus,
              onAddSlot: _showAddSlotSheet,
              onBulkPostpone: _onBulkPostpone,
              onRemoveNewSlots: _removeNewSlots,
            ),
          ),
        ],
        ),
      ),
    );
  }
}
