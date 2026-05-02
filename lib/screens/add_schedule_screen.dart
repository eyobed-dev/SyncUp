import 'package:flutter/material.dart';
import '../models/availability_slot.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../data/live_backend_cache.dart';
import '../widgets/syncup_logo.dart';
import '../widgets/user_profile_drawer.dart';
import '../widgets/find_schedule_slots_view.dart';
import '../utils/week_calendar.dart';
import 'settings_screen.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({
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
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  int _numberOfSlots = 6;
  int _breakBetweenSlotsMinutes = 0;
  int _attendeesPerSlot = 1;
  int _cancelUntilMinutes = 1440; // 1 day before (default)
  String _repeatOption = 'none'; // none, daily, weekly, monthly
  bool _isOnline = false;

  final List<AvailabilitySlot> _addedSlots = [];
  DateTime _slotsWeekStart = startOfWeekSunday(DateTime.now());
  final ValueNotifier<int> _selectedDayIndex = ValueNotifier(
    dayIndexSunWeek(DateTime.now()),
  );
  late TabController _tabController;
  late TabController _addedSlotsTabController;
  int? _addedSlotsExpandedDayIndex;
  int _addedSlotsSlotDuration = 15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
    _addedSlotsTabController = TabController(vsync: this, length: 1);
    _titleController.addListener(_onFormChanged);
    _locationController.addListener(_onFormChanged);
    _meetingLinkController.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.removeListener(_onFormChanged);
    _locationController.removeListener(_onFormChanged);
    _meetingLinkController.removeListener(_onFormChanged);
    _tabController.dispose();
    _addedSlotsTabController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _selectedDayIndex.dispose();
    super.dispose();
  }

  /// Dates to create slots for, based on repeat option.
  List<DateTime> get _datesToAdd {
    final base = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    switch (_repeatOption) {
      case 'daily':
        return List.generate(7, (i) => base.add(Duration(days: i)));
      case 'weekly':
        return List.generate(4, (i) => base.add(Duration(days: i * 7)));
      case 'monthly':
        return List.generate(
          3,
          (i) => DateTime(base.year, base.month + i, base.day),
        );
      default:
        return [base];
    }
  }

  Future<void> _addSlots() async {
    final totalMins =
        _endTime.hour * 60 +
        _endTime.minute -
        (_startTime.hour * 60 + _startTime.minute);
    final breakTotal = _breakBetweenSlotsMinutes * (_numberOfSlots - 1);
    final slotDuration = ((totalMins - breakTotal) / _numberOfSlots).floor();
    final title = _titleController.text.trim();
    final meetingLink =
        _isOnline && _meetingLinkController.text.trim().isNotEmpty
            ? _meetingLinkController.text.trim()
            : null;
    final location =
        _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim();

    if (_isOnline && (meetingLink == null || meetingLink.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an online meeting link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newlyAdded = <AvailabilitySlot>[];
    var slotIndex = 0;
    for (final date in _datesToAdd) {
      final daySlots = _generatedSlotsForDate(date);
      for (var i = 0; i < daySlots.length; i++) {
        final start = daySlots[i];
        final slot = AvailabilitySlot(
          id: 'add-${start.millisecondsSinceEpoch}-$slotIndex',
          startTime: start,
          durationMinutes: slotDuration,
          title: title,
          location: location,
          meetingLink: meetingLink,
        );
        _addedSlots.add(slot);
        newlyAdded.add(slot);
        slotIndex++;
      }
    }
    final d = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    _slotsWeekStart = startOfWeekSunday(d);
    _selectedDayIndex.value = dayIndexSunWeek(d);
    try {
      LiveBackendCache.instance.upsertAvailabilitySlotsLocal(
        ownerId: widget.ownerId,
        slots: newlyAdded,
      );
      await LiveBackendCache.instance.createAvailabilitySlots(
        ownerId: widget.ownerId,
        slots: newlyAdded,
      );
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

  List<DateTime> _generatedSlotsForDate(DateTime date) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      _endTime.hour,
      _endTime.minute,
    );
    final totalMinutes = end.difference(start).inMinutes;
    if (totalMinutes <= 0 || _numberOfSlots < 1) return [];
    final breakTotal = _breakBetweenSlotsMinutes * (_numberOfSlots - 1);
    final availableMinutes = totalMinutes - breakTotal;
    if (availableMinutes <= 0) return [];
    final slotDurationMinutes = availableMinutes ~/ _numberOfSlots;
    return List.generate(
      _numberOfSlots,
      (i) => start.add(
        Duration(
          minutes: i * (slotDurationMinutes + _breakBetweenSlotsMinutes),
        ),
      ),
    );
  }

  int get _slotDurationMinutes {
    final totalMins =
        _endTime.hour * 60 +
        _endTime.minute -
        (_startTime.hour * 60 + _startTime.minute);
    final breakTotal = _breakBetweenSlotsMinutes * (_numberOfSlots - 1);
    if (_numberOfSlots < 1) return 0;
    return ((totalMins - breakTotal) / _numberOfSlots).floor();
  }

  int get _totalGeneratedSlotsCount {
    var total = 0;
    for (final date in _datesToAdd) {
      total += _generatedSlotsForDate(date).length;
    }
    return total;
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _confirmRemoveSlot(AvailabilitySlot slot) {
    final timeStr =
        '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';
    showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm),
            ),
            title: const Text('Remove slot'),
            content: Text(
              'Remove "${slot.title}" at $timeStr?',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: SyncUpTheme.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() => _addedSlots.removeWhere((s) => s.id == slot.id));
      }
    });
  }

  static const _cancelUntilOptions = [
    (minutes: 0, label: 'Until start'),
    (minutes: 15, label: '15 min before'),
    (minutes: 30, label: '30 min before'),
    (minutes: 60, label: '1 hour before'),
    (minutes: 360, label: '6 hours before'),
    (minutes: 720, label: '12 hours before'),
    (minutes: 1440, label: '1 day before'),
    (minutes: 2880, label: '2 days before'),
    (minutes: 4320, label: '3 days before'),
    (minutes: 10080, label: '1 week before'),
    (minutes: 20160, label: '2 weeks before'),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isMobile(context);
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
        onSettingsTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(slotDurationMinutes: 15),
              ),
            ),
        onSignOutTap: widget.onSignOut,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: SyncUpTheme.primary,
            unselectedLabelColor: SyncUpTheme.textSecondary,
            indicatorColor: SyncUpTheme.primary,
            labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: SyncUpTheme.textPrimary,
            ),
            tabs: [
              Tab(text: 'Add'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Added slots'),
                    if (_addedSlots.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SyncUpTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            SyncUpTheme.radiusPill,
                          ),
                        ),
                        child: Text(
                          '${_addedSlots.length}',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: SyncUpTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Add form
                SingleChildScrollView(
                  padding: const EdgeInsets.all(SyncUpTheme.space16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Add Schedule',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: SyncUpTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create availability slots for others to book',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: SyncUpTheme.textSecondary),
                        ),
                        if (_addedSlots.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _ActiveSchedulesList(slots: _addedSlots),
                          const SizedBox(height: 12),
                        ],
                        _AddScheduleSummaryCard(
                          title: _titleController.text.trim(),
                          location: _locationController.text.trim(),
                          isOnline: _isOnline,
                          meetingLink: _meetingLinkController.text.trim(),
                          date: _selectedDate,
                          startTime: _startTime,
                          endTime: _endTime,
                          numberOfSlots: _numberOfSlots,
                          breakMinutes: _breakBetweenSlotsMinutes,
                          attendeesPerSlot: _attendeesPerSlot,
                          repeatOption: _repeatOption,
                          cancelUntilMinutes: _cancelUntilMinutes,
                          slotDurationMinutes: _slotDurationMinutes,
                          totalSlotsCount: _totalGeneratedSlotsCount,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(SyncUpTheme.space12),
                          decoration: BoxDecoration(
                            color: SyncUpTheme.surface,
                            borderRadius: BorderRadius.circular(
                              SyncUpTheme.radiusMd,
                            ),
                            border: Border.all(color: SyncUpTheme.border),
                            boxShadow: SyncUpTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final useRow = constraints.maxWidth > 400;
                                  final fields = [
                                    TextFormField(
                                      controller: _titleController,
                                      decoration: InputDecoration(
                                        labelText: 'Title',
                                        hintText:
                                            'e.g. Consultation, Mentoring, Office hours',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                      ),
                                      validator:
                                          (v) =>
                                              (v == null || v.trim().isEmpty)
                                                  ? 'Required'
                                                  : null,
                                    ),
                                    TextFormField(
                                      controller: _locationController,
                                      decoration: InputDecoration(
                                        labelText: 'Location',
                                        hintText: 'Room 101, Zoom',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                      ),
                                    ),
                                  ];
                                  if (useRow) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: fields[0]),
                                        const SizedBox(width: 12),
                                        Expanded(child: fields[1]),
                                      ],
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      fields[0],
                                      const SizedBox(height: 12),
                                      fields[1],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CompactChip(
                                      icon: Icons.calendar_today,
                                      label: _formatDate(_selectedDate),
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                        );
                                        if (picked != null)
                                          setState(
                                            () => _selectedDate = picked,
                                          );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _CompactChip(
                                      icon: Icons.schedule,
                                      label:
                                          '${_formatTime(_startTime)} – ${_formatTime(_endTime)}',
                                      onTap: () async {
                                        final range = await showDialog<
                                          ({TimeOfDay start, TimeOfDay end})
                                        >(
                                          context: context,
                                          builder:
                                              (ctx) => _TimeRangePicker(
                                                start: _startTime,
                                                end: _endTime,
                                              ),
                                        );
                                        if (range != null) {
                                          setState(() {
                                            _startTime = range.start;
                                            _endTime = range.end;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CompactStepper(
                                      label: 'Slots',
                                      value: _numberOfSlots,
                                      min: 1,
                                      max: 48,
                                      onChanged:
                                          (v) => setState(
                                            () => _numberOfSlots = v,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _CompactStepper(
                                      label: 'Break',
                                      value: _breakBetweenSlotsMinutes,
                                      suffix: 'min',
                                      step: 5,
                                      min: 0,
                                      max: 60,
                                      onChanged:
                                          (v) => setState(
                                            () => _breakBetweenSlotsMinutes = v,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _CompactStepper(
                                      label: 'Max',
                                      value: _attendeesPerSlot,
                                      min: 1,
                                      max: 50,
                                      onChanged:
                                          (v) => setState(
                                            () => _attendeesPerSlot = v,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.videocam_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Online meeting',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: SyncUpTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _isOnline,
                                    onChanged: (v) {
                                      setState(() => _isOnline = v);
                                    },
                                  ),
                                ],
                              ),
                              if (_isOnline) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _meetingLinkController,
                                  decoration: const InputDecoration(
                                    labelText: 'Meeting link',
                                    hintText: 'https://meet.google.com/...',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (!_isOnline) return null;
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Required for online meetings';
                                    final uri = Uri.tryParse(value);
                                    if (uri == null ||
                                        !uri.hasScheme ||
                                        !(uri.scheme == 'http' ||
                                            uri.scheme == 'https')) {
                                      return 'Enter a valid http/https URL';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 12),
                              _CancelUntilSelector(
                                value: _cancelUntilMinutes,
                                options: _cancelUntilOptions,
                                onChanged:
                                    (v) =>
                                        setState(() => _cancelUntilMinutes = v),
                              ),
                              const SizedBox(height: 12),
                              _RepeatSelector(
                                value: _repeatOption,
                                onChanged:
                                    (v) => setState(() => _repeatOption = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _addSlots();
                              if (!mounted) return;
                              setState(() {});
                              _tabController.animateTo(1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added $_totalGeneratedSlotsCount slots: ${_titleController.text}',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add schedule'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab 2: Added slots (Calendar | List sub-tabs)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            'Added slots',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: SyncUpTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (_addedSlots.isNotEmpty)
                            Text(
                              '${_addedSlots.length} total',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: SyncUpTheme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    if (_addedSlots.isNotEmpty) ...[
                      _AddedSlotsWeekRow(
                        weekStart: _slotsWeekStart,
                        onPrev: () {
                          setState(() {
                            _slotsWeekStart = _slotsWeekStart.subtract(
                              const Duration(days: 7),
                            );
                            _addedSlotsExpandedDayIndex = null;
                          });
                        },
                        onNext: () {
                          setState(() {
                            _slotsWeekStart = _slotsWeekStart.add(
                              const Duration(days: 7),
                            );
                            _addedSlotsExpandedDayIndex = null;
                          });
                        },
                      ),
                      TabBar(
                        controller: _addedSlotsTabController,
                        tabs: const [Tab(text: 'Calendar')],
                        labelColor: SyncUpTheme.primary,
                        unselectedLabelColor: SyncUpTheme.textSecondary,
                        indicatorColor: SyncUpTheme.primary,
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _addedSlotsTabController,
                          children: [
                            FindScheduleSlotsView(
                              weekStart: _slotsWeekStart,
                              slotDurationMinutes: _addedSlotsSlotDuration,
                              availabilitySlots: _addedSlots,
                              expandedDayIndex: _addedSlotsExpandedDayIndex,
                              onDayTap:
                                  (i) => setState(
                                    () => _addedSlotsExpandedDayIndex = i,
                                  ),
                              onBack:
                                  () => setState(
                                    () => _addedSlotsExpandedDayIndex = null,
                                  ),
                              onSlotSelected:
                                  (slot) => _confirmRemoveSlot(slot),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: SyncUpTheme.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No slots yet',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: SyncUpTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add slots in the Add tab',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: SyncUpTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact summary card showing current form input.
class _AddScheduleSummaryCard extends StatelessWidget {
  final String title;
  final String location;
  final bool isOnline;
  final String meetingLink;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int numberOfSlots;
  final int breakMinutes;
  final int attendeesPerSlot;
  final String repeatOption;
  final int cancelUntilMinutes;
  final int slotDurationMinutes;
  final int totalSlotsCount;

  const _AddScheduleSummaryCard({
    required this.title,
    required this.location,
    required this.isOnline,
    required this.meetingLink,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.numberOfSlots,
    required this.breakMinutes,
    required this.attendeesPerSlot,
    required this.repeatOption,
    required this.cancelUntilMinutes,
    required this.slotDurationMinutes,
    required this.totalSlotsCount,
  });

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) {
    const m = [
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
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String get _repeatLabel {
    switch (repeatOption) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Once';
    }
  }

  String get _cancelUntilLabel {
    if (cancelUntilMinutes == 0) return 'Until start';
    if (cancelUntilMinutes < 60) return '${cancelUntilMinutes}m before';
    if (cancelUntilMinutes < 1440) return '${cancelUntilMinutes ~/ 60}h before';
    if (cancelUntilMinutes < 10080)
      return '${cancelUntilMinutes ~/ 1440}d before';
    return '${cancelUntilMinutes ~/ 10080}w before';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SyncUpTheme.space10),
      decoration: BoxDecoration(
        color: SyncUpTheme.surface,
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
        border: Border.all(color: SyncUpTheme.border),
        boxShadow: SyncUpTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, size: 18, color: SyncUpTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.isEmpty ? 'Untitled' : title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: SyncUpTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalSlotsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SyncUpTheme.primaryLight,
                    borderRadius: BorderRadius.circular(SyncUpTheme.radiusPill),
                  ),
                  child: Text(
                    '$totalSlotsCount slots',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: SyncUpTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: SyncUpTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SyncUpTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (isOnline) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.link_outlined,
                  size: 14,
                  color: SyncUpTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    meetingLink.isEmpty ? 'Meeting link required' : meetingLink,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: meetingLink.isEmpty
                          ? Colors.red.shade700
                          : SyncUpTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _SummaryChip(
                icon: Icons.calendar_today,
                label: _formatDate(date),
              ),
              _SummaryChip(
                icon: Icons.schedule,
                label: '${_formatTime(startTime)} – ${_formatTime(endTime)}',
              ),
              _SummaryChip(
                icon: Icons.grid_view,
                label: '$numberOfSlots × ${slotDurationMinutes}min',
              ),
              if (breakMinutes > 0)
                _SummaryChip(
                  icon: Icons.pause,
                  label: '${breakMinutes}min break',
                ),
              _SummaryChip(
                icon: Icons.person_outline,
                label:
                    attendeesPerSlot == 1 ? '1-on-1' : 'Max $attendeesPerSlot',
              ),
              _SummaryChip(icon: Icons.repeat, label: _repeatLabel),
              _SummaryChip(icon: Icons.event_busy, label: _cancelUntilLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: SyncUpTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: SyncUpTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Compact list of active schedules (unique title+location) with slot counts.
class _ActiveSchedulesList extends StatelessWidget {
  final List<AvailabilitySlot> slots;

  const _ActiveSchedulesList({required this.slots});

  List<({String title, String? location, int count})> get _groupedSchedules {
    final map = <String, ({String title, String? location, int count})>{};
    for (final s in slots) {
      final key = '${s.title}|${s.location ?? ''}';
      final existing = map[key];
      if (existing == null) {
        map[key] = (title: s.title, location: s.location, count: 1);
      } else {
        map[key] = (
          title: s.title,
          location: s.location,
          count: existing.count + 1,
        );
      }
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _groupedSchedules;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SyncUpTheme.surface,
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
        border: Border.all(color: SyncUpTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat, size: 16, color: SyncUpTheme.primary),
              const SizedBox(width: 6),
              Text(
                'Active schedules',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: SyncUpTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${slots.length} slots',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SyncUpTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children:
                items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SyncUpTheme.primaryLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
                      border: Border.all(
                        color: SyncUpTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(
                            color: SyncUpTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.location != null &&
                            item.location!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.place,
                            size: 12,
                            color: SyncUpTheme.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.location!,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: SyncUpTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SyncUpTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              SyncUpTheme.radiusXs,
                            ),
                          ),
                          child: Text(
                            '${item.count}',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: SyncUpTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RepeatSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RepeatSelector({required this.value, required this.onChanged});

  static const _options = [
    ('none', 'No repeat', Icons.repeat),
    ('daily', 'Every day', Icons.today),
    ('weekly', 'Every week', Icons.date_range),
    ('monthly', 'Every month', Icons.calendar_month),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.repeat, size: 16, color: SyncUpTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Repeat',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SyncUpTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children:
              _options.map((opt) {
                final selected = value == opt.$1;
                return GestureDetector(
                  onTap: () => onChanged(opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? SyncUpTheme.primaryLight.withValues(alpha: 0.6)
                              : SyncUpTheme.background,
                      borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
                      border: Border.all(
                        color:
                            selected ? SyncUpTheme.primary : SyncUpTheme.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.$3,
                          size: 16,
                          color:
                              selected
                                  ? SyncUpTheme.primary
                                  : SyncUpTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt.$2,
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(
                            color:
                                selected
                                    ? SyncUpTheme.primary
                                    : SyncUpTheme.textPrimary,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _CancelUntilSelector extends StatelessWidget {
  final int value;
  final List<({int minutes, String label})> options;
  final ValueChanged<int> onChanged;

  const _CancelUntilSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.event_busy, size: 16, color: SyncUpTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Can cancel until',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SyncUpTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: SyncUpTheme.background,
            borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
            border: Border.all(color: SyncUpTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: SyncUpTheme.primary),
              borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
              dropdownColor: SyncUpTheme.surface,
              items:
                  options
                      .map(
                        (o) => DropdownMenuItem<int>(
                          value: o.minutes,
                          child: Text(
                            o.label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: SyncUpTheme.textPrimary),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (v) => onChanged(v ?? value),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddedSlotsWeekRow extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _AddedSlotsWeekRow({
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
  });

  String _weekBadgeLabel(DateTime weekSunday) {
    final now = DateTime.now();
    final thisWeekSunday = startOfWeekSunday(
      DateTime(now.year, now.month, now.day),
    );
    final displayedSunday = DateTime(
      weekSunday.year,
      weekSunday.month,
      weekSunday.day,
    );
    if (displayedSunday == thisWeekSunday) return 'This week';
    if (displayedSunday.isAfter(thisWeekSunday)) {
      final weeksAhead = displayedSunday.difference(thisWeekSunday).inDays ~/ 7;
      return 'Next ${weeksAhead} week${weeksAhead == 1 ? '' : 's'}';
    }
    final weeksAgo = thisWeekSunday.difference(displayedSunday).inDays ~/ 7;
    return 'Past ${weeksAgo} week${weeksAgo == 1 ? '' : 's'}';
  }

  Color _weekBadgeColor(DateTime weekSunday) {
    final now = DateTime.now();
    final thisWeekSunday = startOfWeekSunday(
      DateTime(now.year, now.month, now.day),
    );
    final displayedSunday = DateTime(
      weekSunday.year,
      weekSunday.month,
      weekSunday.day,
    );
    if (displayedSunday == thisWeekSunday) return SyncUpTheme.primary;
    if (displayedSunday.isAfter(thisWeekSunday)) return Colors.blue.shade700;
    return SyncUpTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final weekSunday = startOfWeekSunday(
      DateTime(weekStart.year, weekStart.month, weekStart.day),
    );
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
    final sat = weekSunday.add(const Duration(days: 6));
    final weekLabel =
        '${months[weekSunday.month - 1]} ${weekSunday.day}–${sat.day} ${weekSunday.year}';
    final badgeColor = _weekBadgeColor(weekSunday);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            tooltip: 'Previous week',
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SyncUpTheme.textPrimary,
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
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _weekBadgeLabel(weekSunday),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: badgeColor,
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
            onPressed: onNext,
            tooltip: 'Next week',
          ),
        ],
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SyncUpTheme.primaryLight.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: SyncUpTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: SyncUpTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: SyncUpTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final ValueChanged<int> onChanged;

  const _CompactStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
        suffix != null
            ? (value > 0 ? '$value $suffix' : 'None')
            : value.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: SyncUpTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _StepperBtn(
              icon: Icons.remove,
              onPressed:
                  value > min
                      ? () => onChanged((value - step).clamp(min, max))
                      : null,
            ),
            Expanded(
              child: Center(
                child: Text(
                  displayValue,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SyncUpTheme.textPrimary,
                  ),
                ),
              ),
            ),
            _StepperBtn(
              icon: Icons.add,
              onPressed:
                  value < max
                      ? () => onChanged((value + step).clamp(min, max))
                      : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? SyncUpTheme.primary : SyncUpTheme.divider,
      borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: enabled ? Colors.white : SyncUpTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TimeRangePicker extends StatefulWidget {
  final TimeOfDay start;
  final TimeOfDay end;

  const _TimeRangePicker({required this.start, required this.end});

  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _start = widget.start;
    _end = widget.end;
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm),
      ),
      title: const Text('Time range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_format(_start)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _start,
                        );
                        if (t != null) setState(() => _start = t);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_format(_end)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _end,
                        );
                        if (t != null) setState(() => _end = t);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (start: _start, end: _end)),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
