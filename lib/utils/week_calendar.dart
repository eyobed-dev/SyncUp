/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Helper functions and utility methods.
 */

// Sunday-first week (US-style): columns 0–6 are Sun–Sat.

/// Date-only start of the week (Sunday) that contains [any].
DateTime startOfWeekSunday(DateTime any) {
  final d = DateTime(any.year, any.month, any.day);
  return d.subtract(Duration(days: d.weekday % 7));
}

/// Strip/list index 0 = Sunday … 6 = Saturday (matches [DateTime.weekday] % 7).
int dayIndexSunWeek(DateTime day) => day.weekday % 7;

const List<String> dayShortNamesSunFirst = [
  'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
];

const List<String> dayLongNamesSunFirst = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
