# SyncUp

SyncUp is a Flutter application designed to connect university students, professors, and staff by bridging the gap between **meeting scheduling** and **indoor campus navigation**. 


## Features

- **Interactive Campus Map:** A custom SVG-based indoor map renderer that smoothly interpolates and scales across different building floors.
- **Indoor Routing & Navigation:** Calculates optimal walking directions across corridors, stairs, and elevators using Dijkstra's algorithm.
- **Meeting Scheduling:** Tetris-style weekly slots view and a per-day calendar view for booking consultations and managing contacts.
- **Backend Sync:** A lightweight, embedded PocketBase database and a Node.js proxy for automated data seeding and authentication.

---

## Project Structure

```text
SyncUp/
├── lib/
│   ├── main.dart                 # App entry, routing, and theme
│   ├── map/                      # Campus Map & Navigation Core
│   │   ├── screens/              # Map view and interaction
│   │   ├── services/             # Graph pathfinder, data loading
│   │   ├── widgets/              # Map painter, floor selector, search
│   │   └── models/               # Graph nodes, rooms, map paths
│   ├── models/                   # Scheduling data models (meetings, users)
│   ├── data/                     # Data providers and local caches
│   ├── screens/                  # Main tabs: Home | Map | Schedule
│   └── widgets/                  # Reusable UI (Slots view, calendar, etc.)
│
└── backend/
    └── pocketbase-api/           # Backend
        ├── src/                  # Express.js API proxy
        ├── scripts/              # DB Bootstrap & data seed scripts
        └── package.json
```

---

## Getting Started

### 1. Start the Backend
The app relies on a local PocketBase instance with pre-seeded users and schedules.
```bash
cd backend/pocketbase-api
npm install
npm run dev
```
*(This automatically bootstraps the database schema and seeds the mock data on port 8080).*

### 2. Run the App
In a new terminal window, run the Flutter application:
```bash
# Web
flutter run -d chrome

# Android / iOS / Desktop
flutter run
```



---

## Implementation Details

### Map Rendering
The indoor map is parsed directly from custom `campus_features.json` data, extracted from legacy SVGs. The `BuildingMapPainter` draws the geometry, applies dynamic color themes, and handles pinch-to-zoom interactive states.

### Navigation Logic
A graph-based approach maps physical nodes (corridors, intersections, rooms). Transitions between floors add vertical weight penalties to simulate real-world stair/elevator travel times.

### Scheduling UI
- **Slots View:** 15-minute slot blocks from 08:00 to 18:00. Meetings overlap naturally and adapt vertically based on duration.
- **Calendar View:** Per-day linear list of events sorted chronologically.

---
*Authors: Team SyncUp @ FIT VUT*
