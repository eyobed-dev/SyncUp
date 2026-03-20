import 'package:flutter/material.dart';
import '../models/availability_slot.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';

/// Calendar-style list of added availability slots (like main screen Calendar tab).
const List<Color> _cardAccentColors = [
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFFEC4899),
  Color(0xFFF59E0B),
];

class AddScheduleSlotsList extends StatelessWidget {
  final List<AvailabilitySlot> slots;
  final DateTime weekStart;
  final ValueNotifier<int> selectedDayIndex;
  final ValueChanged<AvailabilitySlot>? onRemoveSlot;
  final VoidCallback? onPrevWeek;
  final VoidCallback? onNextWeek;
  final bool showWeekNavigation;

  const AddScheduleSlotsList({
    super.key,
    required this.slots,
    required this.weekStart,
    required this.selectedDayIndex,
    this.onRemoveSlot,
    this.onPrevWeek,
    this.onNextWeek,
    this.showWeekNavigation = true,
  });

  String _weekBadgeLabel(DateTime monday) {
    final now = DateTime.now();
    final thisWeekMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final displayedMonday = DateTime(monday.year, monday.month, monday.day);
    if (displayedMonday == thisWeekMonday) return 'This week';
    if (displayedMonday.isAfter(thisWeekMonday)) {
      final weeksAhead = displayedMonday.difference(thisWeekMonday).inDays ~/ 7;
      return 'Next ${weeksAhead} week${weeksAhead == 1 ? '' : 's'}';
    }
    final weeksAgo = thisWeekMonday.difference(displayedMonday).inDays ~/ 7;
    return 'Past ${weeksAgo} week${weeksAgo == 1 ? '' : 's'}';
  }

  Color _weekBadgeColor(DateTime monday) {
    final now = DateTime.now();
    final thisWeekMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final displayedMonday = DateTime(monday.year, monday.month, monday.day);
    if (displayedMonday == thisWeekMonday) return SyncUpTheme.primary;
    if (displayedMonday.isAfter(thisWeekMonday)) return Colors.blue.shade700;
    return SyncUpTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final monday = DateTime(weekStart.year, weekStart.month, weekStart.day)
        .subtract(Duration(days: weekStart.weekday - 1));
    final sun = monday.add(const Duration(days: 6));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekLabel = '${months[monday.month - 1]} ${monday.day}–${sun.day} ${monday.year}';
    final badgeColor = _weekBadgeColor(monday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showWeekNavigation && (onPrevWeek != null || onNextWeek != null))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPrevWeek,
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
                            borderRadius: BorderRadius.circular(
                              SyncUpTheme.radiusXs,
                            ),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _weekBadgeLabel(monday),
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
                  onPressed: onNextWeek,
                  tooltip: 'Next week',
                ),
              ],
            ),
          ),
        _WeekDaySelector(
          weekStart: weekStart,
          selectedIndex: selectedDayIndex,
        ),
        const Divider(height: 1),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: selectedDayIndex,
            builder: (context, dayIndex, _) {
              final monday = DateTime(weekStart.year, weekStart.month, weekStart.day)
                  .subtract(Duration(days: weekStart.weekday - 1));
              final day = monday.add(Duration(days: dayIndex));
              final daySlots = slots.where((s) {
                final sd = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
                final dd = DateTime(day.year, day.month, day.day);
                return sd == dd;
              }).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

              return _DaySlotsList(
                day: day,
                slots: daySlots,
                onRemove: onRemoveSlot,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekDaySelector extends StatelessWidget {
  final DateTime weekStart;
  final ValueNotifier<int> selectedIndex;

  const _WeekDaySelector({
    required this.weekStart,
    required this.selectedIndex,
  });

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final monday = DateTime(weekStart.year, weekStart.month, weekStart.day)
        .subtract(Duration(days: weekStart.weekday - 1));
    final dayWidth = Responsive.value(
      context,
      mobile: 44.0,
      tablet: 52.0,
      desktop: 64.0,
    );
    final selectorHeight = Responsive.value(
      context,
      mobile: 60.0,
      tablet: 64.0,
      desktop: 72.0,
    );

    return SizedBox(
      height: selectorHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.value(context, mobile: 6.0, tablet: 10.0, desktop: 12.0),
          vertical: 6,
        ),
        itemCount: 7,
        itemBuilder: (context, i) {
          final day = monday.add(Duration(days: i));
          return ValueListenableBuilder<int>(
            valueListenable: selectedIndex,
            builder: (context, idx, _) {
              final selected = idx == i;
              return GestureDetector(
                onTap: () => selectedIndex.value = i,
                child: Container(
                  width: dayWidth,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: selected ? SyncUpTheme.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                    border: Border.all(
                      color: selected ? SyncUpTheme.primary : SyncUpTheme.border,
                    ),
                    boxShadow: selected ? SyncUpTheme.cardShadow : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayNames[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? SyncUpTheme.textPrimary : SyncUpTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: selected ? SyncUpTheme.textPrimary : SyncUpTheme.textSecondary,
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
    );
  }
}

class _DaySlotsList extends StatelessWidget {
  final DateTime day;
  final List<AvailabilitySlot> slots;
  final ValueChanged<AvailabilitySlot>? onRemove;

  const _DaySlotsList({
    required this.day,
    required this.slots,
    this.onRemove,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: SyncUpTheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'No slots this day',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: SyncUpTheme.primary.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      );
    }

    final padding = Responsive.value(
      context,
      mobile: 10.0,
      tablet: 12.0,
      desktop: 16.0,
    );
    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: slots.length,
      itemBuilder: (context, i) {
        final slot = slots[i];
        final accentColor = _cardAccentColors[i % _cardAccentColors.length];

        return Container(
          margin: EdgeInsets.only(bottom: padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: accentColor,
                      child: Text(
                        slot.title.isNotEmpty ? slot.title[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      slot.title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          '${_formatTime(slot.startTime)} – ${_formatTime(slot.endTime)}',
                          '${slot.durationMinutes} min',
                          if (slot.location != null) slot.location!,
                        ].join(' • '),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: onRemove != null
                        ? IconButton(
                            icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                            onPressed: () => onRemove!(slot),
                            tooltip: 'Remove',
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
