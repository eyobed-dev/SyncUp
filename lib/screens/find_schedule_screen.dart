import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../models/schedule_owner.dart';
import '../data/schedule_owners_data.dart';
import '../data/availability_data.dart';
import '../data/sample_data.dart';
import '../data/live_backend_cache.dart';
import '../models/availability_slot.dart';
import '../models/meeting.dart';
import '../widgets/syncup_logo.dart';
import '../widgets/user_profile_drawer.dart';
import '../widgets/week_day_selector.dart';
import '../utils/week_calendar.dart';
import 'settings_screen.dart';

class FindScheduleScreen extends StatefulWidget {
  const FindScheduleScreen({
    super.key,
    this.attendeeName = 'SyncUp User',
    this.attendeeUserId,
    this.currentOwnerId,
    this.profileDisplayName = 'SyncUp User',
    this.profileUsername = 'user',
    this.profileRoleLabel = 'Student',
    this.profileUserId,
    this.startInFinder = false,
    this.onSignOut,
  });

  final String attendeeName;
  final String? attendeeUserId;
  final String? currentOwnerId;
  final String profileDisplayName;
  final String profileUsername;
  final String profileRoleLabel;
  final String? profileUserId;
  final bool startInFinder;
  final VoidCallback? onSignOut;

  @override
  State<FindScheduleScreen> createState() => _FindScheduleScreenState();
}

class _FindScheduleScreenState extends State<FindScheduleScreen> {
  DateTime _weekStart = DateTime.now();
  int _slotDurationMinutes = 15;
  ScheduleOwner? _selectedOwner;
  late final ValueNotifier<int> _selectedDayIndex;
  final Set<String> _bookedSlotKeys = <String>{};
  final Set<String> _bookingInFlightSlotKeys = <String>{};
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  final GlobalKey _searchFieldKey = GlobalKey();
  final TextEditingController _cancelReasonController = TextEditingController();
  String _searchQuery = '';
  bool _searchFocused = false;
  bool _isSelectingFromDropdown = false;
  bool _keepDropdownVisible = false;
  Timer? _dropdownHideTimer;
  bool _isSyncing = false;
  List<Meeting> _myBookings = const [];

  DateTime get _weekSunday => startOfWeekSunday(
    DateTime(_weekStart.year, _weekStart.month, _weekStart.day),
  );

  bool get _isStudentView =>
      widget.currentOwnerId == null || widget.currentOwnerId!.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = ValueNotifier(DateTime.now().weekday % 7);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _syncInitial();
  }

  Future<void> _syncInitial() async {
    setState(() => _isSyncing = true);
    final futures = <Future<void>>[syncScheduleOwners()];
    if (_selectedOwner != null) {
      futures.add(syncAvailabilityForOwner(_selectedOwner!.id, _weekSunday));
    }
    await Future.wait(futures);
    List<Meeting> myBookings = _myBookings;
    if (_isStudentView) {
      myBookings = await _fetchMyBookingsForWeek();
    }
    if (mounted) {
      setState(() {
        _myBookings = myBookings;
        _isSyncing = false;
      });
    }
  }

  Future<void> _syncVisibleWeekData() async {
    final owner = _selectedOwner;
    setState(() => _isSyncing = true);
    final futures = <Future<void>>[];
    if (owner != null) {
      futures.add(syncAvailabilityForOwner(owner.id, _weekSunday));
    }
    List<Meeting> myBookings = _myBookings;
    if (_isStudentView) {
      futures.add(
        _fetchMyBookingsForWeek().then((value) {
          myBookings = value;
        }),
      );
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    if (mounted) {
      setState(() {
        _myBookings = myBookings;
        _isSyncing = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_isSelectingFromDropdown) return;
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_selectedOwner != null &&
          _searchController.text.trim().toLowerCase() !=
              _selectedOwner!.name.trim().toLowerCase()) {
        _selectedOwner = null;
      }
    });
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _dropdownHideTimer?.cancel();
      _keepDropdownVisible = true;
      setState(() => _searchFocused = true);
    } else {
      _dropdownHideTimer?.cancel();
      _dropdownHideTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() {
            _searchFocused = false;
            _keepDropdownVisible = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _dropdownHideTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cancelReasonController.dispose();
    _selectedDayIndex.dispose();
    super.dispose();
  }

  Future<List<Meeting>> _fetchMyBookingsForWeek() async {
    await syncMeetingsForWeek(
      _weekSunday,
      ownerId: (widget.currentOwnerId ?? '').trim().isEmpty
          ? 'p1'
          : widget.currentOwnerId!.trim(),
      participantName:
          (widget.attendeeUserId ?? '').trim().isEmpty
              ? widget.attendeeName
              : null,
      participantUserId: widget.attendeeUserId,
    );

    final merged = <String, Meeting>{};
    for (final m in getMeetingsForWeek(_weekSunday)) {
      merged['${m.id}|${m.startTime.toIso8601String()}'] = m;
    }

    bool isMine(Meeting m) {
      // Never treat open availability placeholders as booked meetings.
      if (m.participantName.trim().toLowerCase() == 'open slot') return false;

      final myUserId = (widget.attendeeUserId ?? '').trim();
      final myName = widget.attendeeName.trim().toLowerCase();
      final meetingStudentId = (m.studentId ?? '').trim();
      final meetingName = m.participantName.trim().toLowerCase();

      if (myUserId.isNotEmpty && meetingStudentId.isNotEmpty) {
        return meetingStudentId == myUserId;
      }
      if (myUserId.isNotEmpty && meetingStudentId.isEmpty) {
        // Fallback when backend row lacks studentId.
        return meetingName == myName;
      }
      return meetingName == myName;
    }

    final out = merged.values.where(isMine).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return out;
  }

  void _startFindingMeeting() {
    if (_isStudentView && !widget.startInFinder) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FindScheduleScreen(
                attendeeName: widget.attendeeName,
                attendeeUserId: widget.attendeeUserId,
                currentOwnerId: widget.currentOwnerId,
                profileDisplayName: widget.profileDisplayName,
                profileUsername: widget.profileUsername,
                profileRoleLabel: widget.profileRoleLabel,
                profileUserId: widget.profileUserId,
                startInFinder: true,
                onSignOut: widget.onSignOut,
              ),
        ),
      ).then((_) {
        if (mounted) _syncVisibleWeekData();
      });
      return;
    }
    setState(() {
      _selectedOwner = null;
      _keepDropdownVisible = true;
      _searchFocused = true;
    });
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  /// Converts wildcard pattern (* = any chars, ? = single char) to regex.
  bool _matchesWildcard(String text, String pattern) {
    if (pattern.isEmpty) return true;
    const regexSpecial = r'.+^${}()|[]\';
    final sb = StringBuffer();
    for (final c in pattern.split('')) {
      if (c == '*') {
        sb.write('.*');
      } else if (c == '?') {
        sb.write('.');
      } else if (regexSpecial.contains(c)) {
        sb.write('\\');
        sb.write(c);
      } else {
        sb.write(c);
      }
    }
    try {
      return RegExp(sb.toString(), caseSensitive: false).hasMatch(text);
    } catch (_) {
      return text.toLowerCase().contains(pattern.toLowerCase());
    }
  }

  List<ScheduleOwner> get _filteredOwners {
    var list = getScheduleOwners();
    final currentOwnerId = widget.currentOwnerId;
    if (currentOwnerId != null && currentOwnerId.isNotEmpty) {
      list = list.where((o) => o.id != currentOwnerId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.trim();
      list =
          list.where((o) {
            return _matchesWildcard(o.name, query) ||
                (o.role != null && _matchesWildcard(o.role!, query)) ||
                (o.department != null &&
                    _matchesWildcard(o.department!, query));
          }).toList();
    }
    return list;
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    _syncVisibleWeekData();
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
    _syncVisibleWeekData();
  }

  String get _weekLabel {
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
    final sat = _weekSunday.add(const Duration(days: 6));
    return '${months[_weekSunday.month - 1]} ${_weekSunday.day}–${sat.day} ${_weekSunday.year}';
  }

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

  String _slotKey(ScheduleOwner owner, AvailabilitySlot slot) =>
      '${owner.id}|${slot.id}|${slot.startTime.toIso8601String()}';

  Future<bool> _showSlotConfirmation(
    BuildContext context,
    AvailabilitySlot slot, {
    required ScheduleOwner owner,
  }) {
    final dateStr =
        '${slot.startTime.day}/${slot.startTime.month}/${slot.startTime.year}';
    final timeStr =
        '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${slot.startTime.add(Duration(minutes: slot.durationMinutes)).hour.toString().padLeft(2, '0')}:${slot.startTime.add(Duration(minutes: slot.durationMinutes)).minute.toString().padLeft(2, '0')}';
    final locationStr = slot.location ?? '—';

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => _BookSlotDialog(
            slot: slot,
            owner: owner,
            dateStr: dateStr,
            timeStr: timeStr,
            endStr: endStr,
            locationStr: locationStr,
            onConfirmed: (note) {
              final msg =
                  note.isEmpty
                      ? 'Booked ${slot.title} – $timeStr at $locationStr with ${owner.name}'
                      : 'Booked ${slot.title} – $timeStr with ${owner.name}. Note: $note';
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
    ).then((v) => v == true);
  }

  Future<String?> _showBulkCancelBookingDialog(List<Meeting> bookings) {
    final now = DateTime.now();
    final withinOneDay = bookings.any((b) {
      final startsIn = b.startTime.difference(now);
      return startsIn.inMinutes >= 0 && startsIn <= const Duration(days: 1);
    });
    _cancelReasonController.text =
        'Hello Professor,\n\nI need to cancel my booking due to a scheduling conflict.\n\nThank you.';
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            bookings.length == 1 ? 'Cancel booking?' : 'Cancel ${bookings.length} bookings?',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (withinOneDay)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'Warning: At least one selected meeting is within 1 day. Please include a clear reason to notify the professor.',
                    ),
                  ),
                Text(
                  bookings.length == 1
                      ? 'After cancelling, this slot will become available again.'
                      : 'After cancelling, all selected slots will become available again.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: SyncUpTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cancelReasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Email to professor (reason)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Keep booking'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () {
                final reason = _cancelReasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a cancellation reason.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop(reason);
              },
              child: const Text('Cancel booking'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelStudentBookings(List<Meeting> bookings) async {
    final cancellable = bookings
        .where((b) => b.id.trim().startsWith('booking-'))
        .toList();
    if (cancellable.isEmpty) return;
    final reason = await _showBulkCancelBookingDialog(cancellable);
    if (!mounted || reason == null) return;
    try {
      for (final booking in cancellable) {
        final bookingId = booking.id.trim().substring('booking-'.length);
        await LiveBackendCache.instance.cancelBooking(
          bookingId: bookingId,
          participantUserId: widget.attendeeUserId,
          participantName: widget.attendeeName,
          cancelReason: reason,
        );
      }
      if (!mounted) return;
      await _syncVisibleWeekData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancellable.length == 1
                ? 'Booking cancelled and professor notified.'
                : '${cancellable.length} bookings cancelled and professor notified.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel booking. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    final compact = Responsive.isMobile(context);
    final showStudentListPage = _isStudentView && !widget.startInFinder;
    final selectedOwner = _selectedOwner;
    final weekSunday = _weekSunday;
    final emptySlotCountsByDay =
        selectedOwner == null
            ? const <int>[]
            : List<int>.generate(7, (dayIdx) {
              final dayDate = weekSunday.add(Duration(days: dayIdx));
              return getAvailabilityForOwner(selectedOwner.id, weekSunday)
                  .where((slot) {
                    final t = slot.startTime;
                    return t.year == dayDate.year &&
                        t.month == dayDate.month &&
                        t.day == dayDate.day;
                  })
                  .where((slot) {
                    final key = _slotKey(
                      selectedOwner,
                      slot,
                    );
                    return !_bookedSlotKeys.contains(key) &&
                        !_bookingInFlightSlotKeys.contains(key);
                  })
                  .length;
            });
    final showOwnerDropdown =
        _filteredOwners.isNotEmpty &&
        _selectedOwner == null &&
        (_searchFocused || _keepDropdownVisible || _searchQuery.isNotEmpty);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final searchFieldWidth = (viewportWidth - 24).clamp(220.0, 560.0);
    return Scaffold(
      appBar: AppBar(
        title: SyncUpLogo(size: 28, compact: compact),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                        widget.profileDisplayName.trim().isNotEmpty
                            ? widget.profileDisplayName.trim()[0].toUpperCase()
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
        displayName: widget.profileDisplayName,
        username: widget.profileUsername,
        email: widget.profileUsername.trim().toLowerCase().contains('@')
            ? widget.profileUsername.trim().toLowerCase()
            : '${widget.profileUsername.trim().toLowerCase()}@fit.cvut.cz',
        roleLabel: widget.profileRoleLabel,
        userId: widget.profileUserId,
        onSettingsTap: () async {
          final result = await Navigator.push<int>(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SettingsScreen(
                    slotDurationMinutes: _slotDurationMinutes,
                    onSlotDurationChanged:
                        (v) => setState(() => _slotDurationMinutes = v),
                  ),
            ),
          );
          if (result != null) {
            setState(() => _slotDurationMinutes = result);
          }
        },
        onSignOutTap: widget.onSignOut,
      ),
      body: showStudentListPage
          ? _StudentMeetingsPage(
              bookings: _myBookings,
              onCancelBookings: _cancelStudentBookings,
              onFindMeeting: _startFindingMeeting,
            )
          : Stack(
        children: [
          Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search section
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              color: SyncUpTheme.surface,
              border: Border(bottom: BorderSide(color: SyncUpTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SyncUpTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CompositedTransformTarget(
                      link: _searchLayerLink,
                      child: SizedBox(
                        key: _searchFieldKey,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Search By Name, Profession, Title',
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: SyncUpTheme.textSecondary,
                            ),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: SyncUpTheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _selectedOwner = null;
                                        });
                                      },
                                      tooltip: 'Clear',
                                    )
                                    : null,
                            filled: true,
                            fillColor: SyncUpTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                SyncUpTheme.radiusXs,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SyncUpTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSyncing) const LinearProgressIndicator(minHeight: 2),
          // Week row (same as HomeScreen)
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
          // Slots grid
          if (selectedOwner != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: SyncUpTheme.surface,
                border: Border(bottom: BorderSide(color: SyncUpTheme.border)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List<Widget>.generate(7, (dayIdx) {
                    final count = emptySlotCountsByDay[dayIdx];
                    final hasAny = count > 0;
                    return Container(
                      margin: EdgeInsets.only(right: dayIdx == 6 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasAny
                            ? SyncUpTheme.primary.withValues(alpha: 0.12)
                            : SyncUpTheme.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
                        border: Border.all(
                          color: hasAny
                              ? SyncUpTheme.primary.withValues(alpha: 0.3)
                              : SyncUpTheme.border,
                        ),
                      ),
                      child: Text(
                        '${dayShortNamesSunFirst[dayIdx]}: $count empty',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: hasAny
                                  ? SyncUpTheme.primary
                                  : SyncUpTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                          final weekSunday = _weekSunday;
                          final sundayDate = DateTime(
                            weekSunday.year,
                            weekSunday.month,
                            weekSunday.day,
                          );

                          final owner = _selectedOwner;

                          String fmtTime(DateTime dt) =>
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                          return Column(
                            children: [
                              WeekDaySelector(
                                weekStart: _weekStart,
                                selectedIndex: _selectedDayIndex,
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child:
                                    owner == null
                                        ? widget.startInFinder
                                            ? Center(
                                                child: Text(
                                                  'Select a professor from search to view available slots',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: SyncUpTheme
                                                            .textSecondary,
                                                      ),
                                                ),
                                              )
                                            : Builder(
                                          builder: (context) {
                                            final bookings = [..._myBookings]
                                              ..sort(
                                                (a, b) => a.startTime.compareTo(b.startTime),
                                              );
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.fromLTRB(
                                                    12,
                                                    10,
                                                    12,
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: SyncUpTheme.surface,
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: SyncUpTheme.border,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'My meetings',
                                                              style: Theme.of(
                                                                context,
                                                              ).textTheme.titleSmall?.copyWith(
                                                                color: SyncUpTheme
                                                                    .textPrimary,
                                                                fontWeight:
                                                                    FontWeight.w700,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              bookings.isEmpty
                                                                  ? 'No bookings yet. Choose a professor to book a meeting.'
                                                                  : '${bookings.length} booking${bookings.length == 1 ? '' : 's'} this week',
                                                              style: Theme.of(
                                                                context,
                                                              ).textTheme.bodySmall?.copyWith(
                                                                color: SyncUpTheme
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      OutlinedButton.icon(
                                                        onPressed:
                                                            _startFindingMeeting,
                                                        icon: const Icon(
                                                          Icons.search,
                                                          size: 18,
                                                        ),
                                                        label: const Text(
                                                          'Find meeting',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child:
                                                      bookings.isEmpty
                                                          ? Center(
                                                            child: Text(
                                                              'No bookings this week yet',
                                                              style: Theme.of(
                                                                context,
                                                              ).textTheme.bodyMedium?.copyWith(
                                                                color: SyncUpTheme
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          )
                                                          : ListView.separated(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  12,
                                                                ),
                                                            itemCount:
                                                                bookings.length,
                                                            separatorBuilder:
                                                                (_, __) =>
                                                                    const SizedBox(
                                                                      height: 8,
                                                                    ),
                                                            itemBuilder: (
                                                              context,
                                                              i,
                                                            ) {
                                                              final booking =
                                                                  bookings[i];
                                                              final end = booking
                                                                  .startTime
                                                                  .add(
                                                                    Duration(
                                                                      minutes:
                                                                          booking
                                                                              .durationMinutes,
                                                                    ),
                                                                  );
                                                              final title =
                                                                  (booking.topic ??
                                                                              '')
                                                                          .trim()
                                                                          .isNotEmpty
                                                                      ? booking
                                                                          .topic!
                                                                          .trim()
                                                                      : 'Booked session';
                                                              final subtitleParts =
                                                                  <String>[
                                                                    '${dayShortNamesSunFirst[booking.startTime.weekday % 7]}',
                                                                    if ((booking.location ??
                                                                            '')
                                                                        .trim()
                                                                        .isNotEmpty)
                                                                      booking
                                                                          .location!
                                                                          .trim(),
                                                                    '${booking.durationMinutes} min',
                                                                  ];
                                                              return Material(
                                                                color:
                                                                    Colors.white,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                                child: ListTile(
                                                                  contentPadding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            6,
                                                                      ),
                                                                  leading: Icon(
                                                                    Icons
                                                                        .event_available,
                                                                    color: SyncUpTheme
                                                                        .primary,
                                                                  ),
                                                                  title: Text(
                                                                    '${fmtTime(booking.startTime)} - ${fmtTime(end)}',
                                                                    style: Theme.of(
                                                                      context,
                                                                    ).textTheme.titleSmall?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w800,
                                                                      color: SyncUpTheme
                                                                          .textPrimary,
                                                                    ),
                                                                  ),
                                                                  subtitle: Text(
                                                                    '$title · ${subtitleParts.join(' · ')}',
                                                                    style: Theme.of(
                                                                      context,
                                                                    ).textTheme.bodySmall?.copyWith(
                                                                      color: SyncUpTheme
                                                                          .textSecondary,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                ),
                                              ],
                                            );
                                          },
                                        )
                                        : ValueListenableBuilder<int>(
                                          valueListenable: _selectedDayIndex,
                                          builder: (context, dayIdx, _) {
                                            final dayDate = sundayDate.add(
                                              Duration(days: dayIdx),
                                            );
                                            final slots =
                                                getAvailabilityForOwner(
                                                      owner.id,
                                                      _weekSunday,
                                                    )
                                                    .where((s) {
                                                      final d = s.startTime;
                                                      return d.year ==
                                                              dayDate.year &&
                                                          d.month ==
                                                              dayDate.month &&
                                                          d.day == dayDate.day;
                                                    })
                                                    .where(
                                                      (s) =>
                                                          !_bookedSlotKeys
                                                              .contains(
                                                                _slotKey(
                                                                  owner,
                                                                  s,
                                                                ),
                                                              ),
                                                    )
                                                    .toList()
                                                  ..sort(
                                                    (a, b) => a.startTime
                                                        .compareTo(b.startTime),
                                                  );

                                            if (slots.isEmpty) {
                                              return Center(
                                                child: Text(
                                                  'No available slots for ${owner.name} this day',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            SyncUpTheme
                                                                .textSecondary,
                                                      ),
                                                ),
                                              );
                                            }

                                            return ListView.separated(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    12,
                                                    10,
                                                    12,
                                                    12,
                                                  ),
                                              itemCount: slots.length,
                                              separatorBuilder:
                                                  (_, __) =>
                                                      const SizedBox(height: 6),
                                              itemBuilder: (context, i) {
                                                final s = slots[i];
                                                final end = s.startTime.add(
                                                  Duration(
                                                    minutes: s.durationMinutes,
                                                  ),
                                                );
                                                final timeLabel =
                                                    '${fmtTime(s.startTime)} – ${fmtTime(end)}';
                                                final subtitleParts = <String>[
                                                  if (s.title.trim().isNotEmpty)
                                                    s.title.trim(),
                                                  if ((s.location ?? '')
                                                      .trim()
                                                      .isNotEmpty)
                                                    (s.location!).trim(),
                                                  if ((s.meetingLink ?? '')
                                                      .trim()
                                                      .isNotEmpty)
                                                    'Online',
                                                ];

                                                return Material(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    title: Text(
                                                      timeLabel,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color:
                                                                SyncUpTheme
                                                                    .textPrimary,
                                                          ),
                                                    ),
                                                    subtitle:
                                                        subtitleParts.isEmpty
                                                            ? null
                                                            : Text(
                                                              subtitleParts
                                                                  .join(' · '),
                                                              style: Theme.of(
                                                                    context,
                                                                  )
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color:
                                                                        SyncUpTheme
                                                                            .textSecondary,
                                                                  ),
                                                            ),
                                                    trailing: const Icon(
                                                      Icons.chevron_right,
                                                    ),
                                                    onTap: () async {
                                                      final key = _slotKey(owner, s);
                                                      if (_bookedSlotKeys.contains(key) ||
                                                          _bookingInFlightSlotKeys.contains(key)) {
                                                        return;
                                                      }
                                                      setState(() {
                                                        _bookingInFlightSlotKeys.add(key);
                                                        _bookedSlotKeys.add(key);
                                                      });
                                                      final ok =
                                                          await _showSlotConfirmation(
                                                            context,
                                                            s,
                                                            owner: owner,
                                                          );
                                                      if (!mounted) return;
                                                      if (!ok) {
                                                        setState(() {
                                                          _bookingInFlightSlotKeys.remove(key);
                                                          _bookedSlotKeys.remove(key);
                                                        });
                                                        return;
                                                      }
                                                      try {
                                                        await LiveBackendCache
                                                            .instance
                                                            .bookSlot(
                                                              ownerId: owner.id,
                                                              slotId: s.id,
                                                              weekStart:
                                                                  _weekSunday,
                                                              participantName:
                                                                  widget
                                                                      .attendeeName,
                                                              participantUserId:
                                                                  widget
                                                                      .attendeeUserId,
                                                            );
                                                        if (!mounted) return;
                                                        setState(() {
                                                          _bookingInFlightSlotKeys.remove(key);
                                                        });
                                                        await _syncVisibleWeekData();
                                                      } catch (_) {
                                                        if (!mounted) return;
                                                        setState(() {
                                                          _bookingInFlightSlotKeys.remove(key);
                                                          _bookedSlotKeys.remove(key);
                                                        });
                                                        ScaffoldMessenger.of(
                                                          this.context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Booking failed. Slot may already be taken.',
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
          if (showOwnerDropdown)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: CompositedTransformFollower(
                  link: _searchLayerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 46),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: searchFieldWidth,
                        constraints: const BoxConstraints(maxHeight: 260),
                        decoration: BoxDecoration(
                          color: SyncUpTheme.surface,
                          borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
                          border: Border.all(color: SyncUpTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _filteredOwners.length,
                          itemBuilder: (context, i) {
                            final owner = _filteredOwners[i];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _dropdownHideTimer?.cancel();
                                  _isSelectingFromDropdown = true;
                                  setState(() {
                                    _selectedOwner = owner;
                                    _searchController.text = owner.name;
                                    _searchQuery = owner.name.toLowerCase();
                                    _keepDropdownVisible = false;
                                  });
                                  _isSelectingFromDropdown = false;
                                  _searchFocusNode.unfocus();
                                  _syncVisibleWeekData();
                                },
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: SyncUpTheme.primary
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      owner.name.isNotEmpty
                                          ? owner.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: SyncUpTheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    owner.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: SyncUpTheme.textPrimary,
                                        ),
                                  ),
                                  subtitle: owner.role != null
                                      ? Text(
                                          owner.role!,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: SyncUpTheme.textSecondary,
                                              ),
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentMeetingsPage extends StatefulWidget {
  const _StudentMeetingsPage({
    required this.bookings,
    required this.onCancelBookings,
    required this.onFindMeeting,
  });

  final List<Meeting> bookings;
  final Future<void> Function(List<Meeting> bookings) onCancelBookings;
  final VoidCallback onFindMeeting;

  @override
  State<_StudentMeetingsPage> createState() => _StudentMeetingsPageState();
}

class _StudentMeetingsPageState extends State<_StudentMeetingsPage> {
  bool _manageMode = false;
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    String fmtTime(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final sorted = [...widget.bookings]..sort((a, b) => a.startTime.compareTo(b.startTime));
    final validIds = sorted.map((m) => m.id).toSet();
    _selectedIds.removeWhere((id) => !validIds.contains(id));
    final selectedMeetings = sorted.where((m) => _selectedIds.contains(m.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: SyncUpTheme.surface,
            border: Border(bottom: BorderSide(color: SyncUpTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My meetings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: SyncUpTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sorted.isEmpty
                          ? 'No bookings yet'
                          : '${sorted.length} booking${sorted.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SyncUpTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onFindMeeting,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Find meeting'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _manageMode = !_manageMode;
                        if (!_manageMode) _selectedIds.clear();
                      });
                    },
                    icon: Icon(_manageMode ? Icons.check : Icons.tune, size: 18),
                    label: Text(_manageMode ? 'Done' : 'Manage'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_manageMode && _selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: SyncUpTheme.zenGreenLight,
              borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${_selectedIds.length} selected',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SyncUpTheme.textPrimary,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: selectedMeetings.isEmpty
                          ? null
                          : () async {
                              await widget.onCancelBookings(selectedMeetings);
                              if (mounted) {
                                setState(() => _selectedIds.clear());
                              }
                            },
                      child: const Text('Cancel selected'),
                    ),
                    IconButton(
                      tooltip: 'Clear selection',
                      onPressed: () => setState(() => _selectedIds.clear()),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Text(
                    'You have no meetings booked yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SyncUpTheme.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final booking = sorted[i];
                    final end = booking.startTime.add(
                      Duration(minutes: booking.durationMinutes),
                    );
                    final title = (booking.topic ?? '').trim().isNotEmpty
                        ? booking.topic!.trim()
                        : 'Booked session';
                    final subtitleParts = <String>[
                      '${dayShortNamesSunFirst[booking.startTime.weekday % 7]}',
                      if ((booking.location ?? '').trim().isNotEmpty)
                        booking.location!.trim(),
                      '${booking.durationMinutes} min',
                    ];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        leading: _manageMode
                            ? Checkbox(
                                value: _selectedIds.contains(booking.id),
                                onChanged: (_) {
                                  setState(() {
                                    if (_selectedIds.contains(booking.id)) {
                                      _selectedIds.remove(booking.id);
                                    } else {
                                      _selectedIds.add(booking.id);
                                    }
                                  });
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              )
                            : Icon(
                                Icons.event_available,
                                color: SyncUpTheme.primary,
                              ),
                        title: Text(
                          '${fmtTime(booking.startTime)} - ${fmtTime(end)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SyncUpTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '$title · ${subtitleParts.join(' · ')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SyncUpTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SyncUpTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: SyncUpTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _BookSlotDialog extends StatefulWidget {
  const _BookSlotDialog({
    required this.slot,
    required this.owner,
    required this.dateStr,
    required this.timeStr,
    required this.endStr,
    required this.locationStr,
    required this.onConfirmed,
  });

  final AvailabilitySlot slot;
  final ScheduleOwner owner;
  final String dateStr;
  final String timeStr;
  final String endStr;
  final String locationStr;
  final void Function(String note) onConfirmed;

  @override
  State<_BookSlotDialog> createState() => _BookSlotDialogState();
}

class _BookSlotDialogState extends State<_BookSlotDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final owner = widget.owner;
    final locationStr = widget.locationStr;
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360, maxHeight: maxDialogHeight),
        child: Container(
          decoration: BoxDecoration(
            color: SyncUpTheme.surface,
            borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm),
            boxShadow: SyncUpTheme.modalShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(SyncUpTheme.space12),
                decoration: BoxDecoration(
                  color: SyncUpTheme.primaryLight.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(SyncUpTheme.radiusSm),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SyncUpTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          SyncUpTheme.radiusSm,
                        ),
                      ),
                      child: Icon(
                        Icons.event_available,
                        color: SyncUpTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book this slot',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: SyncUpTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confirm your booking',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: SyncUpTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SyncUpTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: SyncUpTheme.background,
                        borderRadius: BorderRadius.circular(
                          SyncUpTheme.radiusMd,
                        ),
                        border: Border.all(color: SyncUpTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 20,
                            color: SyncUpTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.timeStr} – ${widget.endStr}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SyncUpTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${widget.dateStr} • ${slot.durationMinutes} min',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color: SyncUpTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoChip(icon: Icons.title, label: slot.title),
                    if (locationStr != '—') ...[
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: locationStr,
                      ),
                    ],
                    if ((slot.meetingLink ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.link_outlined,
                        label: slot.meetingLink!.trim(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: SyncUpTheme.primaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          SyncUpTheme.radiusXs,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: SyncUpTheme.primary,
                            child: Text(
                              owner.name.isNotEmpty
                                  ? owner.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'With ${owner.name}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: SyncUpTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'Add a note for this booking...',
                        prefixIcon: Icon(
                          Icons.note,
                          size: 20,
                          color: SyncUpTheme.textSecondary,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            SyncUpTheme.radiusXs,
                          ),
                        ),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          final note = _noteController.text.trim();
                          widget.onConfirmed(note);
                          Navigator.pop(context, true);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
