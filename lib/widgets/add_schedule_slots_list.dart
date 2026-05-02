import 'package:flutter/material.dart';
import '../models/availability_slot.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../utils/week_calendar.dart';
import 'week_day_selector.dart';

/// Calendar-style list of added availability slots (like main screen Calendar tab).
const List<Color> _cardAccentColors = [
  Color(0xFF0F9FA8),
  Color(0xFF0E7490),
  Color(0xFF0891B2),
  Color(0xFF14B8A6),
  Color(0xFF06B6D4),
  Color(0xFF22D3EE),
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

  String _weekBadgeLabel(DateTime weekSunday) {
    final now = DateTime.now();
    final thisWeekSunday = startOfWeekSunday(DateTime(now.year, now.month, now.day));
    final displayedSunday = DateTime(weekSunday.year, weekSunday.month, weekSunday.day);
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
    final thisWeekSunday = startOfWeekSunday(DateTime(now.year, now.month, now.day));
    final displayedSunday = DateTime(weekSunday.year, weekSunday.month, weekSunday.day);
    if (displayedSunday == thisWeekSunday) return SyncUpTheme.primary;
    if (displayedSunday.isAfter(thisWeekSunday)) return const Color(0xFF0E7490);
    return SyncUpTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final weekSunday = startOfWeekSunday(
      DateTime(weekStart.year, weekStart.month, weekStart.day),
    );
    final sat = weekSunday.add(const Duration(days: 6));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekLabel = '${months[weekSunday.month - 1]} ${weekSunday.day}–${sat.day} ${weekSunday.year}';
    final badgeColor = _weekBadgeColor(weekSunday);

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
                  onPressed: onNextWeek,
                  tooltip: 'Next week',
                ),
              ],
            ),
          ),
        WeekDaySelector(
          weekStart: weekStart,
          selectedIndex: selectedDayIndex,
        ),
        const Divider(height: 1),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: selectedDayIndex,
            builder: (context, dayIndex, _) {
              final ws = startOfWeekSunday(
                DateTime(weekStart.year, weekStart.month, weekStart.day),
              );
              final day = ws.add(Duration(days: dayIndex));
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
