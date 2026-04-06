import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../models/schedule_owner.dart';
import '../data/schedule_owners_data.dart';
import '../data/availability_data.dart';
import '../models/availability_slot.dart';
import '../widgets/syncup_logo.dart';
import '../widgets/user_profile_drawer.dart';
import '../widgets/find_schedule_slots_view.dart';
import '../utils/week_calendar.dart';
import 'settings_screen.dart';

class FindScheduleScreen extends StatefulWidget {
  const FindScheduleScreen({super.key});

  @override
  State<FindScheduleScreen> createState() => _FindScheduleScreenState();
}

class _FindScheduleScreenState extends State<FindScheduleScreen> {
  DateTime _weekStart = DateTime.now();
  int _slotDurationMinutes = 15;
  int? _expandedDayIndex;
  ScheduleOwner? _selectedOwner;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _searchFocused = false;
  bool _isSelectingFromDropdown = false;
  bool _keepDropdownVisible = false;
  Timer? _dropdownHideTimer;

  DateTime get _weekSunday => startOfWeekSunday(
        DateTime(_weekStart.year, _weekStart.month, _weekStart.day),
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
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
    super.dispose();
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

  String get _weekLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final sat = _weekSunday.add(const Duration(days: 6));
    return '${months[_weekSunday.month - 1]} ${_weekSunday.day}–${sat.day} ${_weekSunday.year}';
  }

  String get _weekBadgeLabel {
    final now = DateTime.now();
    final thisWeekSunday = startOfWeekSunday(DateTime(now.year, now.month, now.day));
    final displayedSunday = DateTime(_weekSunday.year, _weekSunday.month, _weekSunday.day);
    if (displayedSunday == thisWeekSunday) return 'This week';
    if (displayedSunday.isAfter(thisWeekSunday)) {
      final weeksAhead = displayedSunday.difference(thisWeekSunday).inDays ~/ 7;
      return 'Next ${weeksAhead} week${weeksAhead == 1 ? '' : 's'}';
    }
    final weeksAgo = thisWeekSunday.difference(displayedSunday).inDays ~/ 7;
    return 'Past ${weeksAgo} week${weeksAgo == 1 ? '' : 's'}';
  }

  void _showSlotConfirmation(BuildContext context, AvailabilitySlot slot) {
    final dateStr = '${slot.startTime.day}/${slot.startTime.month}/${slot.startTime.year}';
    final timeStr =
        '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${slot.startTime.add(Duration(minutes: slot.durationMinutes)).hour.toString().padLeft(2, '0')}:${slot.startTime.add(Duration(minutes: slot.durationMinutes)).minute.toString().padLeft(2, '0')}';
    final locationStr = slot.location ?? '—';
    final noteController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: SyncUpTheme.surface,
            borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm),
            boxShadow: SyncUpTheme.modalShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                        borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm),
                      ),
                      child: Icon(Icons.event_available, color: SyncUpTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book this slot',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: SyncUpTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confirm your booking',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: SyncUpTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(SyncUpTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Time slot highlight
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: SyncUpTheme.background,
                        borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                        border: Border.all(color: SyncUpTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 20, color: SyncUpTheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$timeStr – $endStr',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: SyncUpTheme.textPrimary,
                                      ),
                                ),
                                Text(
                                  '$dateStr • ${slot.durationMinutes} min',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: SyncUpTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Info rows
                    _InfoChip(icon: Icons.title, label: slot.title),
                    if (locationStr != '—') ...[
                      const SizedBox(height: 8),
                      _InfoChip(icon: Icons.location_on_outlined, label: locationStr),
                    ],
                    const SizedBox(height: 12),
                    // With owner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: SyncUpTheme.primaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: SyncUpTheme.primary,
                            child: Text(
                              _selectedOwner!.name.isNotEmpty ? _selectedOwner!.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'With ${_selectedOwner!.name}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: SyncUpTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Note
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'Add a note for this booking...',
                        prefixIcon: Icon(Icons.note, size: 20, color: SyncUpTheme.textSecondary),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
                        ),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          final note = noteController.text.trim();
                          Navigator.pop(ctx);
                          final msg = note.isEmpty
                              ? 'Booked ${slot.title} – $timeStr at $locationStr with ${_selectedOwner!.name}'
                              : 'Booked ${slot.title} – $timeStr with ${_selectedOwner!.name}. Note: $note';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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
    ).then((_) => noteController.dispose());
  }

  Color get _weekBadgeColor {
    final now = DateTime.now();
    final thisWeekSunday = startOfWeekSunday(DateTime(now.year, now.month, now.day));
    final displayedSunday = DateTime(_weekSunday.year, _weekSunday.month, _weekSunday.day);
    if (displayedSunday == thisWeekSunday) return SyncUpTheme.primary;
    if (displayedSunday.isAfter(thisWeekSunday)) return Colors.blue.shade700;
    return SyncUpTheme.textSecondary;
  }

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
      endDrawer: UserProfileDrawer(
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search section
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              color: SyncUpTheme.surface,
              border: Border(
                bottom: BorderSide(color: SyncUpTheme.border),
              ),
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
                    TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Search By Name, Profession, Title',
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: SyncUpTheme.textSecondary,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 20, color: SyncUpTheme.textSecondary),
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
                              borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
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
                    if (_filteredOwners.isNotEmpty &&
                            _selectedOwner == null &&
                            (_searchFocused || _keepDropdownVisible || _searchQuery.isNotEmpty))
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                              color: SyncUpTheme.surface,
                          borderRadius: BorderRadius.circular(SyncUpTheme.radiusXs),
                          border: Border.all(color: SyncUpTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
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
                                },
                                child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: SyncUpTheme.primary.withValues(alpha: 0.15),
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
                  ],
                ),
              ],
            ),
          ),
          // Week row (same as HomeScreen)
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
          // Slots grid
          Expanded(
            child: _selectedOwner == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 48,
                          color: SyncUpTheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Select a person to view their schedule',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: SyncUpTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final slots = getAvailabilityForOwner(_selectedOwner!.id, _weekStart);
                      if (slots.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: SyncUpTheme.textSecondary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No availability this week',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: SyncUpTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }
                      return FindScheduleSlotsView(
                        weekStart: _weekStart,
                        slotDurationMinutes: _slotDurationMinutes,
                        availabilitySlots: slots,
                        expandedDayIndex: _expandedDayIndex,
                        onDayTap: (i) => setState(() => _expandedDayIndex = i),
                        onBack: () => setState(() => _expandedDayIndex = null),
                        onSlotSelected: (slot) => _showSlotConfirmation(context, slot),
                        onSlotDurationChanged: (v) => setState(() => _slotDurationMinutes = v),
                      );
                    },
                  ),
          ),
        ],
      ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SyncUpTheme.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

