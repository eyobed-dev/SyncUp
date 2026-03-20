# SyncUp

A Flutter app for connecting teachers and students, professionals, experts, and colleagues across academic and professional fields. Schedule and view meetings in a tetris-style slots view or per-day calendar.

## Structure

```
lib/
├── main.dart                 # App entry, SyncUpApp
├── models/
│   └── meeting.dart          # Meeting model (participant, time, duration)
├── data/
│   └── sample_data.dart      # Demo meetings for the current week
├── screens/
│   ├── main_screen.dart      # Bottom nav: Home | +Add | List
│   ├── home_screen.dart      # Tabs: Slots | Calendar + week navigation
│   ├── add_schedule_screen.dart  # Add Schedule screen
│   └── find_schedule_screen.dart      # Find Schedule – search professors, coaches, mentors
└── widgets/
    ├── slots_view.dart       # Tetris-style week grid
    └── calendar_view.dart    # Per-day week view
```

## Implementation Summary

### Bottom Navigation
- **Home**: Main view with Slots and Calendar tabs
- **+Add**: Placeholder for scheduling new meetings
- **List**: Placeholder for contacts and meetings list

### Slots View (Tetris-style)
- **Y-axis**: 15-minute slots from 08:00 to 18:00 (40 rows)
- **X-axis**: 7 days (Mon–Sun)
- **Meeting blocks**: Positioned by start time; height = duration (e.g. 30 min = 2 rows)
- Each block shows: avatar (initial), participant name, subject (if duration ≥ 30 min)
- Blocks stack vertically by time; overlapping meetings on the same day appear in sequence
- Scrollable vertically and horizontally

### Calendar View
- Horizontal day selector for the week (Mon–Sun with date)
- Per-day list of meetings sorted by time
- Empty state when no meetings

### Week Navigation
- Previous/next week buttons in the app bar
- Displays current week range (e.g. `25/2 - 3/3`)

## Run

```bash
flutter run
```
