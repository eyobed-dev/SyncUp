import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../models/meeting.dart';
import '../data/sample_data.dart';
import '../widgets/slots_view.dart';
import '../widgets/calendar_view.dart';
import '../widgets/current_meeting_card.dart';
import '../widgets/dismissed_meeting_button.dart';
import '../widgets/syncup_logo.dart';
import '../widgets/user_profile_drawer.dart';
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
  Timer? _currentMeetingTimer;

  DateTime get _monday =>
      _weekStart.subtract(Duration(days: _weekStart.weekday - 1));

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
    _selectedDayIndex = ValueNotifier(DateTime.now().weekday - 1);
    _clock = ValueNotifier(DateTime.now());
    _slotDurationMinutes = ValueNotifier(15);
    _currentMeetingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) _clock.value = DateTime.now();
      },
    );
  }

  void _openSettings() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
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

  Meeting? get _currentMeeting {
    final m = getCurrentMeeting(_weekStart);
    if (m == null || _dismissedMeetingIds.contains(m.id)) return null;
    return m;
  }

  /// Current meeting that was dismissed – show restore button.
  Meeting? get _dismissedCurrentMeeting {
    final m = getCurrentMeeting(_weekStart);
    if (m == null || !_dismissedMeetingIds.contains(m.id)) return null;
    return m;
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
    final sun = _monday.add(const Duration(days: 6));
    return '${_monday.day}–${sun.day}';
  }

  String get _monthLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[_monday.month - 1];
  }

  String get _weekLabel => '$_monthLabel $_weekRange ${_monday.year}';

  /// Returns badge label for the displayed week: this week, past N week(s), or next N week(s).
  String get _weekBadgeLabel {
    final now = DateTime.now();
    final thisWeekMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final displayedMonday = DateTime(_monday.year, _monday.month, _monday.day);
    if (displayedMonday == thisWeekMonday) return 'This week';
    if (displayedMonday.isAfter(thisWeekMonday)) {
      final weeksAhead = displayedMonday.difference(thisWeekMonday).inDays ~/ 7;
      return 'Next ${weeksAhead} week${weeksAhead == 1 ? '' : 's'}';
    }
    final weeksAgo = thisWeekMonday.difference(displayedMonday).inDays ~/ 7;
    return 'Past ${weeksAgo} week${weeksAgo == 1 ? '' : 's'}';
  }

  Color get _weekBadgeColor {
    final now = DateTime.now();
    final thisWeekMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final displayedMonday = DateTime(_monday.year, _monday.month, _monday.day);
    if (displayedMonday == thisWeekMonday) return SyncUpTheme.primary;
    if (displayedMonday.isAfter(thisWeekMonday)) return Colors.blue.shade700;
    return SyncUpTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final compactAppBar = Responsive.isMobile(context);
    return Scaffold(
      appBar: AppBar(
        title: SyncUpLogo(
          size: 28,
          compact: compactAppBar,
        ),
        actions: [
          Builder(
            builder: (context) => GestureDetector(
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
              border: Border(
                bottom: BorderSide(color: SyncUpTheme.border),
              ),
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
            tabs: const [
              Tab(text: 'Calendar'),
              Tab(text: 'List'),
            ],
          ),
          ValueListenableBuilder<DateTime>(
            valueListenable: _clock,
            builder: (context, _, __) {
              final current = _currentMeeting;
              final dismissed = _dismissedCurrentMeeting;
              if (current != null) {
                return Flexible(
                  child: SingleChildScrollView(
                    child: CurrentMeetingCard(
                      meeting: current,
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
                      onDismiss: () {
                        setState(() {
                          _dismissedMeetingIds.add(current.id);
                        });
                      },
                    ),
                  ),
                );
              }
              if (dismissed != null) {
                return Flexible(
                  child: SingleChildScrollView(
                    child: DismissedMeetingButton(
                      meeting: dismissed,
                      onTap: () {
                        setState(() {
                          _dismissedMeetingIds.remove(dismissed.id);
                        });
                      },
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
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
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: SlotsView(
              key: ValueKey(_expandedDayIndex ?? -1),
              weekStart: _weekStart,
              slotDuration: _slotDurationMinutes,
              expandedDayIndex: _expandedDayIndex,
              onDayTap: (i) => setState(() => _expandedDayIndex = i),
              onBack: () => setState(() => _expandedDayIndex = null),
              tickClock: _tabController.index == 0 ? _clock : null,
            ),
          ),
          CalendarView(
            weekStart: _weekStart,
            selectedDayIndex: _selectedDayIndex,
            liveClock: _tabController.index == 1 ? _clock : null,
          ),
        ],
      ),
    ),
        ],
      ),
    );
  }
}
