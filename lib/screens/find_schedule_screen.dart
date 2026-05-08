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
import 'settings_screen.dart';
import 'package:sync_up/theme/sync_up_colors.dart';

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
  
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  final GlobalKey _searchFieldKey = GlobalKey();
  final TextEditingController _cancelReasonController = TextEditingController();
  
  String _searchQuery = '';
  bool _searchFocused = false;
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
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _syncInitial();
    
    if (widget.startInFinder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_searchFocusNode);
      });
    }
  }

  Future<void> _syncInitial() async {
    setState(() => _isSyncing = true);
    final futures = <Future<void>>[syncScheduleOwners()];
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
    setState(() => _isSyncing = true);
    
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

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
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
      if (m.isOpenSlot) return false;

      final myUserId = (widget.attendeeUserId ?? '').trim();
      final myName = widget.attendeeName.trim().toLowerCase();
      final meetingStudentId = (m.studentId ?? '').trim();
      final meetingName = m.participantName.trim().toLowerCase();

      if (myUserId.isNotEmpty && meetingStudentId.isNotEmpty) {
        return meetingStudentId == myUserId;
      }
      if (myUserId.isNotEmpty && meetingStudentId.isEmpty) {
        return meetingName == myName;
      }
      return meetingName == myName;
    }

    final out = merged.values.where(isMine).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return out;
  }

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
      list = list.where((o) {
        return _matchesWildcard(o.name, query) ||
            (o.role != null && _matchesWildcard(o.role!, query)) ||
            (o.department != null && _matchesWildcard(o.department!, query));
      }).toList();
    }
    return list;
  }

  Future<String?> _showCancelBookingDialog(Meeting booking) {
    _cancelReasonController.text =
        'Hello Professor,\n\nI need to cancel my booking due to a scheduling conflict.\n\nThank you.';
    
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd)),
          title: const Text('Cancel booking?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'After cancelling, this slot will become available again.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cancelReasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Email to professor (reason)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm)),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text('Keep booking'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () {
                final reason = _cancelReasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a cancellation reason.')),
                  );
                  return;
                }
                Navigator.of(ctx).pop(reason);
              },
              child: Text('Cancel booking'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _cancelSingleBooking(Meeting booking) async {
    final reason = await _showCancelBookingDialog(booking);
    if (!mounted || reason == null) return false;
    
    try {
      final bookingId = booking.id.trim().substring('booking-'.length);
      await LiveBackendCache.instance.cancelBooking(
        bookingId: bookingId,
        participantUserId: widget.attendeeUserId,
        participantName: widget.attendeeName,
        cancelReason: reason,
      );
      
      if (!mounted) return true;
      await _syncVisibleWeekData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled and professor notified.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel booking. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  Future<void> _showPriorMinutesForBooking(Meeting booking) async {
    try {
      await syncPriorSessionsForBooking(booking);
      if (!mounted) return;
      final prior = priorSessionsForBooking(booking)
          .where((s) =>
              s.startTime.isBefore(DateTime.now()) &&
              (((s.minutes ?? '').trim().isNotEmpty) ||
                  ((s.deliberations ?? '').trim().isNotEmpty)))
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              booking.ownerName?.trim().isNotEmpty == true
                  ? 'Previous minutes with ${booking.ownerName}'
                  : 'Previous minutes',
            ),
            content: SizedBox(
              width: 520,
              child: prior.isEmpty
                  ? const Text('No previous minutes found for this professor.')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: prior.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, i) {
                        final session = prior[i];
                        final dateLabel =
                            '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if ((session.minutes ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Minutes',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text((session.minutes ?? '').trim()),
                            ],
                            if ((session.deliberations ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Decisions',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text((session.deliberations ?? '').trim()),
                            ],
                          ],
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load previous minutes'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onProfessorSelected(ScheduleOwner owner) {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() => _searchQuery = '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ProfessorBookingSheet(
        owner: owner,
        weekSunday: _weekSunday,
        attendeeName: widget.attendeeName,
        attendeeUserId: widget.attendeeUserId,
        onBookingComplete: _syncVisibleWeekData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isMobile(context);
    final showOwnerDropdown = _filteredOwners.isNotEmpty &&
        (_searchFocused || _keepDropdownVisible || _searchQuery.isNotEmpty);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final searchFieldWidth = (viewportWidth - 32).clamp(220.0, 800.0);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            title: SyncUpLogo(size: 28, compact: compact),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              // User Avatar
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: context.colors.primary,
                      child: Text(
                        widget.profileDisplayName.trim().isNotEmpty
                            ? widget.profileDisplayName.trim()[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: context.colors.surface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
                  builder: (context) => SettingsScreen(
                    slotDurationMinutes: _slotDurationMinutes,
                    onSlotDurationChanged: (v) => setState(() => _slotDurationMinutes = v),
                  ),
                ),
              );
              if (result != null) {
                setState(() => _slotDurationMinutes = result);
              }
            },
            onSignOutTap: widget.onSignOut,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Hero Search Bar ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                      child: CompositedTransformTarget(
                        link: _searchLayerLink,
                        child: SizedBox(
                          key: _searchFieldKey,
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: context.colors.textSecondary.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search for a professor...',
                                hintStyle: TextStyle(color: context.colors.textSecondary.withValues(alpha: 0.7)),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    Icons.search,
                                    size: 22,
                                    color: context.colors.primary,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isSyncing) const LinearProgressIndicator(minHeight: 2),

              // --- My Meetings Dashboard ---
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'My Meetings',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (_myBookings.isNotEmpty)
                                Text(
                                  '${_myBookings.length} upcoming',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _myBookings.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 48, color: context.colors.border),
                                      const SizedBox(height: 16),
                                      Text(
                                        'You have no upcoming meetings.',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: context.colors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  itemCount: _myBookings.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    final booking = _myBookings[i];
                                    final end = booking.startTime.add(
                                      Duration(minutes: booking.durationMinutes),
                                    );
                                    final bookingDate = DateTime(
                                      booking.startTime.year,
                                      booking.startTime.month,
                                      booking.startTime.day,
                                    );
                                    final today = DateTime.now();
                                    final todayDate = DateTime(
                                      today.year,
                                      today.month,
                                      today.day,
                                    );
                                    final prevBookingDate = i > 0
                                        ? DateTime(
                                            _myBookings[i - 1].startTime.year,
                                            _myBookings[i - 1].startTime.month,
                                            _myBookings[i - 1].startTime.day,
                                          )
                                        : null;
                                    final showDateHeader =
                                        i == 0 || prevBookingDate != bookingDate;
                                    final isTodayGroup = bookingDate == todayDate;
                                    
                                    String fmtTime(DateTime dt) =>
                                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                                    final title = (booking.topic ?? '').trim().isNotEmpty
                                        ? booking.topic!.trim()
                                        : 'Booked session';
                                    final dateTitle =
                                        '${dayShortNamesSunFirst[booking.startTime.weekday % 7]} '
                                        '${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}';
                                        
                                    final subtitleParts = <String>[
                                      if ((booking.ownerName ?? '').trim().isNotEmpty)
                                        booking.ownerName!.trim(),
                                      if ((booking.location ?? '').trim().isNotEmpty)
                                        booking.location!.trim(),
                                      '${booking.durationMinutes} min',
                                    ];

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (showDateHeader) ...[
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                                            child: Row(
                                              children: [
                                                Text(
                                                  dateTitle,
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                        color: context.colors.textPrimary,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                ),
                                                if (isTodayGroup) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: context.colors.primaryLight.withValues(alpha: 0.45),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      'Today',
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                            color: context.colors.primary,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                        Dismissible(
                                          key: ValueKey(booking.id),
                                          direction: DismissDirection.endToStart,
                                          confirmDismiss: (direction) async {
                                            return await _cancelSingleBooking(booking);
                                          },
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(right: 24),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDC2626),
                                              borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                                            ),
                                            child: Icon(Icons.delete_outline, color: context.colors.surface, size: 28),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: context.colors.surface,
                                              borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.03),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
                                            ),
                                            child: Stack(
                                              children: [
                                                ListTile(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  leading: Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: context.colors.primaryLight.withValues(alpha: 0.3),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.event_available, color: context.colors.primary, size: 20),
                                                  ),
                                                  title: Text(
                                                    '${fmtTime(booking.startTime)} - ${fmtTime(end)}',
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w800,
                                                      color: context.colors.textPrimary,
                                                    ),
                                                  ),
                                                  subtitle: Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(
                                                      '$title\n${subtitleParts.join(' · ')}',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: context.colors.textSecondary,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                  isThreeLine: true,
                                                  trailing: compact
                                                      ? IconButton(
                                                          icon: Icon(
                                                            Icons.history_outlined,
                                                            color: context.colors.primary,
                                                          ),
                                                          tooltip: 'Previous minutes',
                                                          onPressed: () =>
                                                              _showPriorMinutesForBooking(booking),
                                                        )
                                                      : null,
                                                ),
                                                if (!compact)
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          visualDensity: VisualDensity.compact,
                                                          icon: Icon(
                                                            Icons.history_outlined,
                                                            size: 18,
                                                            color: context.colors.primary,
                                                          ),
                                                          tooltip: 'Previous minutes',
                                                          onPressed: () =>
                                                              _showPriorMinutesForBooking(booking),
                                                        ),
                                                        IconButton(
                                                          visualDensity: VisualDensity.compact,
                                                          icon: Icon(
                                                            Icons.close,
                                                            size: 18,
                                                            color: context.colors.textSecondary
                                                                .withValues(alpha: 0.5),
                                                          ),
                                                          tooltip: 'Cancel Booking',
                                                          onPressed: () => _cancelSingleBooking(booking),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // --- Overlay Search Results Dropdown ---
        if (showOwnerDropdown)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _searchFocusNode.unfocus();
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: CompositedTransformFollower(
                  link: _searchLayerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 60), 
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: searchFieldWidth,
                        constraints: const BoxConstraints(maxHeight: 320),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filteredOwners.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: context.colors.border.withValues(alpha: 0.3)),
                            itemBuilder: (context, i) {
                              final owner = _filteredOwners[i];
                              return InkWell(
                                onTap: () => _onProfessorSelected(owner),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                        child: Text(
                                          owner.name.isNotEmpty ? owner.name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: context.colors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              owner.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: context.colors.textPrimary,
                                              ),
                                            ),
                                            if (owner.role != null)
                                              Text(
                                                owner.role!,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: context.colors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
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
            ),
          ),
      ],
    );
  }
}

// ==========================================
// Sleek Bottom Sheet for Booking
// ==========================================
class _ProfessorBookingSheet extends StatefulWidget {
  final ScheduleOwner owner;
  final DateTime weekSunday;
  final String attendeeName;
  final String? attendeeUserId;
  final VoidCallback onBookingComplete;

  const _ProfessorBookingSheet({
    required this.owner,
    required this.weekSunday,
    required this.attendeeName,
    required this.attendeeUserId,
    required this.onBookingComplete,
  });

  @override
  State<_ProfessorBookingSheet> createState() => _ProfessorBookingSheetState();
}

class _ProfessorBookingSheetState extends State<_ProfessorBookingSheet> {
  late ValueNotifier<int> _selectedDayIndex;
  bool _isLoading = true;
  final Set<String> _bookedSlotKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = ValueNotifier(0);
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    await syncAvailabilityForOwner(widget.owner.id, widget.weekSunday);
    
    // Auto-select logic
    int bestDay = DateTime.now().weekday % 7; 
    for (int i = bestDay; i < 7; i++) {
      if (_getEmptySlotsCountForDay(i) > 0) {
        bestDay = i;
        break;
      }
    }
    
    if (mounted) {
      setState(() {
        _selectedDayIndex.value = bestDay;
        _isLoading = false;
      });
    }
  }

  int _getEmptySlotsCountForDay(int dayIdx) {
    final dayDate = widget.weekSunday.add(Duration(days: dayIdx));
    return getAvailabilityForOwner(widget.owner.id, widget.weekSunday)
        .where((slot) =>
            slot.startTime.year == dayDate.year &&
            slot.startTime.month == dayDate.month &&
            slot.startTime.day == dayDate.day)
        .where((slot) => !_bookedSlotKeys.contains(_slotKey(widget.owner, slot)))
        .length;
  }

  String _slotKey(ScheduleOwner owner, AvailabilitySlot slot) =>
      '${owner.id}|${slot.id}|${slot.startTime.toIso8601String()}';

  String fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<({String note, List<SharedDocument> sharedDocuments})?> _showSlotConfirmation(
    BuildContext context,
    AvailabilitySlot slot,
  ) {
    final dateStr = '${slot.startTime.day}/${slot.startTime.month}/${slot.startTime.year}';
    final timeStr = fmtTime(slot.startTime);
    final endStr = fmtTime(slot.startTime.add(Duration(minutes: slot.durationMinutes)));
    final locationStr = slot.location ?? '—';

    ({String note, List<SharedDocument> sharedDocuments})? result;
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _BookSlotDialog(
        slot: slot,
        owner: widget.owner,
        dateStr: dateStr,
        timeStr: timeStr,
        endStr: endStr,
        locationStr: locationStr,
        onConfirmed: (note, sharedDocuments) {
          result = (note: note, sharedDocuments: sharedDocuments);
        },
      ),
    ).then((v) => v == true ? result : null);
  }

  // Clever UI Typography: Merges Days, Dates, and Slots into one clean row
  Widget _buildCleverCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (dayIdx) {
          final dayDate = widget.weekSunday.add(Duration(days: dayIdx));
          final count = _getEmptySlotsCountForDay(dayIdx);
          
          return ValueListenableBuilder<int>(
            valueListenable: _selectedDayIndex,
            builder: (context, selectedIdx, _) {
              final isSelected = selectedIdx == dayIdx;
              final hasSlots = count > 0;

              return GestureDetector(
                onTap: () => _selectedDayIndex.value = dayIdx,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? context.colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayShortNamesSunFirst[dayIdx].toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? context.colors.surface.withValues(alpha: 0.8) : context.colors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: isSelected ? FontWeight.w800 : (hasSlots ? FontWeight.w700 : FontWeight.w400),
                          color: isSelected ? context.colors.surface : (hasSlots ? context.colors.textPrimary : context.colors.border),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSlots ? '$count open' : 'Full',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? context.colors.surface : (hasSlots ? context.colors.primary : context.colors.border),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                  child: Text(
                    widget.owner.name.isNotEmpty ? widget.owner.name[0].toUpperCase() : '?',
                    style: TextStyle(color: context.colors.primary, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.owner.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      if (widget.owner.department != null)
                        Text(
                          widget.owner.department!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            
            _buildCleverCalendar(),
            const Divider(height: 24),

            // Slots List
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: _selectedDayIndex,
                builder: (context, dayIdx, _) {
                  final dayDate = widget.weekSunday.add(Duration(days: dayIdx));
                  final slots = getAvailabilityForOwner(widget.owner.id, widget.weekSunday)
                      .where((s) =>
                          s.startTime.year == dayDate.year &&
                          s.startTime.month == dayDate.month &&
                          s.startTime.day == dayDate.day)
                      .where((s) => !_bookedSlotKeys.contains(_slotKey(widget.owner, s)))
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  if (slots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 40, color: context.colors.border),
                          const SizedBox(height: 16),
                          Text(
                            'No available slots on this day.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: slots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = slots[i];
                      final end = s.startTime.add(Duration(minutes: s.durationMinutes));
                      final timeLabel = '${fmtTime(s.startTime)} – ${fmtTime(end)}';
                      
                      final subtitleParts = <String>[
                        if (s.title.trim().isNotEmpty) s.title.trim(),
                        if ((s.location ?? '').trim().isNotEmpty) (s.location!).trim(),
                        if ((s.meetingLink ?? '').trim().isNotEmpty) 'Online',
                      ];

                      return InkWell(
                        onTap: () async {
                          final key = _slotKey(widget.owner, s);
                          final bookingInput = await _showSlotConfirmation(context, s);
                          if (!mounted || bookingInput == null) return;

                          setState(() => _bookedSlotKeys.add(key));

                          try {
                            await LiveBackendCache.instance.bookSlot(
                              ownerId: widget.owner.id,
                              slotId: s.id,
                              weekStart: widget.weekSunday,
                              participantName: widget.attendeeName,
                              participantUserId: widget.attendeeUserId,
                              note: bookingInput.note,
                              sharedDocuments: bookingInput.sharedDocuments,
                            );
                            if (mounted) {
                              widget.onBookingComplete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking Confirmed!')),
                              );
                              Navigator.pop(context); // Close the sheet automatically
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(() => _bookedSlotKeys.remove(key));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to book slot.')),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeLabel,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: context.colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (subtitleParts.isNotEmpty)
                                      Text(
                                        subtitleParts.join(' · '),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: context.colors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: context.colors.primary,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'Book',
                                  style: TextStyle(
                                    color: context.colors.surface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// Dialogs & Helpers 
// ==========================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.colors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textPrimary),
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
  final void Function(String note, List<SharedDocument> sharedDocuments) onConfirmed;

  @override
  State<_BookSlotDialog> createState() => _BookSlotDialogState();
}

class _BookSlotDialogState extends State<_BookSlotDialog> {
  late final TextEditingController _noteController;
  late final TextEditingController _sharedDocsController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _sharedDocsController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _sharedDocsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final locationStr = widget.locationStr;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.event_available, color: context.colors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Booking',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: context.colors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 20, color: context.colors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.timeStr} – ${widget.endStr}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${widget.dateStr} • ${slot.durationMinutes} min',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoChip(icon: Icons.title, label: slot.title),
                      if (locationStr != '—') ...[
                        const SizedBox(height: 12),
                        _InfoChip(icon: Icons.location_on_outlined, label: locationStr),
                      ],
                      const SizedBox(height: 20),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          prefixIcon: Icon(Icons.note, size: 20, color: context.colors.textSecondary),
                          filled: true,
                          fillColor: context.colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _sharedDocsController,
                        decoration: InputDecoration(
                          labelText: 'Shared document links (one URL per line)',
                          prefixIcon: Icon(
                            Icons.attach_file_outlined,
                            size: 20,
                            color: context.colors.textSecondary,
                          ),
                          filled: true,
                          fillColor: context.colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            final docs = _sharedDocsController.text
                                .split('\n')
                                .map((line) => line.trim())
                                .where((line) => line.isNotEmpty)
                                .map((url) {
                                  final uri = Uri.tryParse(url);
                                  if (uri == null) {
                                    return SharedDocument(title: '', url: url);
                                  }
                                  final segments = uri.pathSegments;
                                  final fileName = segments.isNotEmpty
                                      ? segments.last
                                      : uri.host;
                                  return SharedDocument(
                                    title: fileName.trim(),
                                    url: url,
                                  );
                                })
                                .toList();
                            widget.onConfirmed(_noteController.text.trim(), docs);
                            Navigator.pop(context, true);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          child: Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
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

// ==========================================
// Date & Time Helpers
// ==========================================

DateTime startOfWeekSunday(DateTime date) {
  final int daysToSubtract = date.weekday % 7;
  final DateTime sunday = date.subtract(Duration(days: daysToSubtract));
  return DateTime(sunday.year, sunday.month, sunday.day);
}

const List<String> dayShortNamesSunFirst = [
  'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
];