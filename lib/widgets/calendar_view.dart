import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../data/sample_data.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../utils/week_calendar.dart';
import 'meeting_list_card.dart';
import 'week_day_selector.dart';

/// Per-day calendar view for a selected week.
/// Tap a day to show its meetings in the list below.
class CalendarView extends StatelessWidget {
  final DateTime weekStart;
  final ValueNotifier<int> selectedDayIndex;
  /// Meetings for the displayed week (sample + user slots, excluding hidden).
  final List<Meeting> meetings;

  /// When non-null (e.g. List tab active), list highlights update from this notifier.
  final ValueListenable<DateTime>? liveClock;

  const CalendarView({
    super.key,
    required this.weekStart,
    required this.selectedDayIndex,
    required this.meetings,
    this.liveClock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WeekDaySelector(
          weekStart: weekStart,
          selectedIndex: selectedDayIndex,
        ),
        const Divider(height: 1),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: selectedDayIndex,
            builder: (context, dayIndex, _) {
              final weekSunday = startOfWeekSunday(
                DateTime(weekStart.year, weekStart.month, weekStart.day),
              );
              final day = weekSunday.add(Duration(days: dayIndex));
              final dayMeetings = meetings
                  .where((m) {
                    final md = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
                    final dd = DateTime(day.year, day.month, day.day);
                    return md == dd;
                  })
                  .toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

              Widget list(Meeting? current) => _DayMeetingsList(
                    meetings: dayMeetings,
                    currentMeeting: current,
                  );

              final live = liveClock;
              if (live == null) {
                return list(getCurrentMeetingFromList(meetings));
              }
              return ValueListenableBuilder<DateTime>(
                valueListenable: live,
                builder: (context, _, __) => list(getCurrentMeetingFromList(meetings)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayMeetingsList extends StatelessWidget {
  final List<Meeting> meetings;
  final Meeting? currentMeeting;

  const _DayMeetingsList({
    required this.meetings,
    this.currentMeeting,
  });

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
        return RepaintBoundary(
          child: Container(
            margin: EdgeInsets.only(bottom: itemGap),
            child: MeetingListCard(
              meeting: meetings[i],
              colorIndex: i,
              currentMeeting: currentMeeting,
            ),
          ),
        );
      },
    );
  }
}
