import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../data/sample_data.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';

/// Left accent colors for list cards (matches slot design).
const List<Color> _cardAccentColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Violet
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Emerald
  Color(0xFFEC4899), // Pink
  Color(0xFFF59E0B), // Amber
];

/// Per-day calendar view for a selected week.
/// Tap a day to show its meetings in the list below.
class CalendarView extends StatelessWidget {
  final DateTime weekStart;
  final ValueNotifier<int> selectedDayIndex;

  /// When non-null (e.g. List tab active), list highlights update from this notifier.
  final ValueListenable<DateTime>? liveClock;

  const CalendarView({
    super.key,
    required this.weekStart,
    required this.selectedDayIndex,
    this.liveClock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              final meetings = getSampleMeetings(monday)
                  .where((m) {
                    final md = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
                    final dd = DateTime(day.year, day.month, day.day);
                    return md == dd;
                  })
                  .toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

              Widget list(Meeting? current) => _DayMeetingsList(
                    day: day,
                    meetings: meetings,
                    currentMeeting: current,
                  );

              final live = liveClock;
              if (live == null) {
                return list(getCurrentMeeting(monday));
              }
              return ValueListenableBuilder<DateTime>(
                valueListenable: live,
                builder: (context, _, __) => list(getCurrentMeeting(monday)),
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
      child: ValueListenableBuilder<int>(
        valueListenable: selectedIndex,
        builder: (context, idx, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.value(context, mobile: 6.0, tablet: 10.0, desktop: 12.0),
              vertical: 6,
            ),
            itemCount: 7,
            itemBuilder: (context, i) {
              final day = monday.add(Duration(days: i));
              final selected = idx == i;
              return GestureDetector(
                onTap: () => selectedIndex.value = i,
                child: Container(
                  width: dayWidth,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: selected ? SyncUpTheme.zenGreenLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                    border: Border.all(
                      color: selected ? SyncUpTheme.zenGreen : SyncUpTheme.border,
                    ),
                    boxShadow: selected ? SyncUpTheme.cardShadow : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayNames[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.normal,
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

class _DayMeetingsList extends StatelessWidget {
  final DateTime day;
  final List<Meeting> meetings;
  final Meeting? currentMeeting;

  const _DayMeetingsList({
    required this.day,
    required this.meetings,
    this.currentMeeting,
  });

  /// Meeting is at least 1 day in the future (can cancel).
  static bool _canCancel(Meeting m) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetingDate = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
    return meetingDate.isAfter(today);
  }

  void _showCancelConfirmation(BuildContext context, Meeting m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel meeting?'),
        content: Text(
          'Cancel the meeting with ${m.participantName} on ${_formatDate(m.startTime)}? This cannot be undone.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Implement cancel
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Meeting with ${m.participantName} cancelled'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Cancel meeting'),
          ),
        ],
      ),
    );
  }

  void _showPostponeConfirmation(BuildContext context, Meeting m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Postpone meeting?'),
        content: Text(
          'Postpone the meeting with ${m.participantName}? You can reschedule it later.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Implement postpone
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Meeting with ${m.participantName} postponed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Postpone'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: SyncUpTheme.zenGreen.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'No meetings this day',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: SyncUpTheme.zenGreen.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      );
    }

    final padding = Responsive.value(
      context,
      mobile: 6.0,
      tablet: 8.0,
      desktop: 10.0,
    );
    const itemGap = 4.0;
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      itemCount: meetings.length,
      itemBuilder: (context, i) {
        final m = meetings[i];
        final accentColor = _cardAccentColors[i % _cardAccentColors.length];
        final isCurrent = currentMeeting?.id == m.id;
        final now = DateTime.now();
        final isOngoing = isCurrent &&
            !now.isBefore(m.startTime) &&
            now.isBefore(m.endTime);

        final highlight = SyncUpTheme.primary.withValues(alpha: 0.4);

        return RepaintBoundary(
          child: Container(
            margin: EdgeInsets.only(bottom: itemGap),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border(
                left: BorderSide(color: accentColor, width: 4),
                top: isCurrent ? BorderSide(color: highlight, width: 1.5) : BorderSide.none,
                right: isCurrent ? BorderSide(color: highlight, width: 1.5) : BorderSide.none,
                bottom: isCurrent ? BorderSide(color: highlight, width: 1.5) : BorderSide.none,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCurrent
                      ? SyncUpTheme.primary.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isCurrent ? 8 : 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: accentColor,
                    child: Text(
                      m.participantName.isNotEmpty
                          ? m.participantName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOngoing
                                        ? SyncUpTheme.primary
                                        : SyncUpTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOngoing ? 'In progress' : 'Just ended',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: isOngoing
                                            ? SyncUpTheme.primary
                                            : SyncUpTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          m.displayLabel,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            '${_formatTime(m.startTime)} – ${_formatTime(m.endTime)}',
                            if (m.location != null) m.location!,
                          ].join(' • '),
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_canCancel(m)) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => _showCancelConfirmation(context, m),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFDC2626)),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: () => _showPostponeConfirmation(context, m),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: SyncUpTheme.primary,
                                  side: const BorderSide(color: SyncUpTheme.primary),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text('Postpone', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
