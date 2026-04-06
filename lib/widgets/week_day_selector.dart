import 'package:flutter/material.dart';

import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';
import '../utils/week_calendar.dart';

/// Horizontal Mon–Sun strip for the current week (same as List tab).
class WeekDaySelector extends StatelessWidget {
  final DateTime weekStart;
  final ValueNotifier<int> selectedIndex;

  const WeekDaySelector({
    super.key,
    required this.weekStart,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final weekSunday = startOfWeekSunday(
      DateTime(weekStart.year, weekStart.month, weekStart.day),
    );
    final selectorHeight = Responsive.value(
      context,
      mobile: 60.0,
      tablet: 64.0,
      desktop: 72.0,
    );
    final hPad = Responsive.value(context, mobile: 6.0, tablet: 10.0, desktop: 12.0);

    return SizedBox(
      height: selectorHeight,
      child: ValueListenableBuilder<int>(
        valueListenable: selectedIndex,
        builder: (context, idx, _) {
          return Padding(
            padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 6),
            child: Row(
              children: List.generate(7, (i) {
                final day = weekSunday.add(Duration(days: i));
                final selected = idx == i;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => selectedIndex.value = i,
                      child: Container(
                        width: double.infinity,
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
                              dayShortNamesSunFirst[i],
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    color: selected ? SyncUpTheme.textPrimary : SyncUpTheme.textSecondary,
                                  ),
                              overflow: TextOverflow.ellipsis,
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
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
