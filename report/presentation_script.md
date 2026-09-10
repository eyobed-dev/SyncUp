# SyncUp Presentation Outline & Script

*Use this outline to build your Google Slides or PowerPoint presentation. Each section represents one slide.*

---

## Slide 1: Title
**Title:** SyncUp
**Subtitle:** University Appointment Scheduling & Indoor Campus Navigation
**Visuals:** SyncUp Logo / High-quality app mockup on a phone.
**Text:** 
- Team Members: Adar Otieno, **Eyobed Awel Nuri (Captain)**, Pengwei Jiang, Mengran Zhao

**Speaker Notes:** 
"Hello everyone, we are the SyncUp team. Today we are excited to showcase our solution to two major pain points experienced by university students and faculty: scheduling meetings and navigating complex campus layouts."

---

## Slide 2: The Problem
**Title:** The Challenge
**Visuals:** Icons representing confusion, calendar conflicts, and a maze.
**Text:**
- Coordinating meetings between students and professors is often chaotic and requires endless email chains.
- New students and visitors struggle to find specific offices or labs on large university campuses.
- Existing solutions are disjointed (separate calendars, separate campus maps).

**Speaker Notes:** 
"Have you ever spent a week emailing a professor just to find a 15-minute slot? And once you finally booked it, you spent 20 minutes getting lost in the university corridors trying to find their office? That's the problem we set out to solve."

---

## Slide 3: The Solution (SyncUp)
**Title:** Introducing SyncUp
**Visuals:** A split graphic showing a calendar on one side and a map on the other, merging together.
**Text:**
- A unified platform combining robust scheduling with interactive indoor mapping.
- Two core components seamlessly integrated into one cross-platform Flutter application.
- Real-time synchronization.

**Speaker Notes:** 
"Our solution is SyncUp. It's a cross-platform mobile application that seamlessly merges an intuitive scheduling system with a custom-built indoor campus map. It bridges the gap between booking a meeting and actually getting there."

---

## Slide 4: Scheduling System (Student View)
**Title:** Empowering Students
**Visuals:** Screenshot: `assets/stud home.png` and `assets/stud book.png` (side-by-side or overlapping).
**Text:**
- Searchable directory of professors.
- Real-time weekly availability grid.
- Select an open slot, specify a topic, and book instantly.

**Speaker Notes:** 
"For students, we wanted to make booking as easy as possible. They can browse a directory of professors, view their real-time availability on a weekly grid, and instantly book a consultation slot. No more guessing when a professor might be free."

---

## Slide 5: Scheduling System (Professor View)
**Title:** Empowering Professors
**Visuals:** Screenshot: `assets/prof home.png` and `assets/prof create slots.png`.
**Text:**
- Management dashboard for recurring availability.
- Intuitive time-range picker.
- Easy handling of exceptions (holidays, conferences).
- Weekly overview of incoming requests.

**Speaker Notes:** 
"For professors, the system acts as a powerful assistant. They can define recurring availability rules—like 'every Tuesday morning'—and block out exceptions for holidays. The dashboard provides a clear, organized view of all incoming student requests."

---

## Slide 6: Indoor Campus Mapping (FITmaps)
**Title:** Never Get Lost Again
**Visuals:** Screenshot: `assets/campus map.png`.
**Text:**
- Interactive digital layout of the university campus (FITmaps).
- Built using Flutter’s custom rendering engine.
- Search functionality for specific rooms and labs.

**Speaker Notes:** 
"Once a meeting is booked, you need to know where you're going. Our second core feature is FITmaps—an interactive indoor map built natively in Flutter. Users can pan, zoom, and search for specific rooms across the campus."

---

## Slide 7: Multi-Floor Navigation & Pathfinding
**Title:** Intelligent Pathfinding
**Visuals:** Screenshot: `assets/campus routing multi floor.png`.
**Text:**
- Custom Dijkstra's algorithm implementation.
- Step-by-step routing across multiple floors.
- Automatically incorporates stairs and elevators.

**Speaker Notes:** 
"Our routing engine isn't just a 2D line. It uses a custom implementation of Dijkstra's algorithm on a pre-computed graph to handle multi-floor navigation. It knows where the stairs and elevators are, and gives you step-by-step instructions to change floors."

---

## Slide 8: The "Magic" Integration
**Title:** Tying It All Together
**Visuals:** Flow diagram: Booking Detail Screen -> Tapping 'Navigate' -> Map Screen with active route.
**Text:**
- From an appointment detail view, simply tap "Navigate".
- The map automatically plots a route from your current location directly to the professor's office.

**Speaker Notes:** 
"The true magic of SyncUp is the integration. When it's time for your meeting, you just open the appointment detail view and tap 'Navigate'. The app instantly bridges the scheduling data with the map data, plotting a direct route to the professor's door."

---

## Slide 9: Technical Architecture
**Title:** Under The Hood
**Visuals:** Diagram showing Flutter App <-> Node.js API <-> PocketBase.
**Text:**
- **Frontend:** Flutter (Cross-platform, Custom `CustomPaint` engine for SVG map parsing).
- **Backend:** Node.js Express API & PocketBase.
- **Database:** Lightweight embedded SQLite with real-time WebSocket synchronization.

**Speaker Notes:** 
"Technically, the app is built in Flutter, which allowed us to create a highly optimized custom rendering engine for the maps. Our backend utilizes PocketBase, a lightweight SQLite database that provides out-of-the-box real-time synchronization, preventing any double-booking conflicts."

---

## Slide 10: Future Development
**Title:** The Roadmap
**Visuals:** Icons for Bluetooth, an expanding map, and AR glasses.
**Text:**
- Real-time user positioning via BLE (Bluetooth Low Energy) beacons.
- Expanding map dataset to encompass the entire university grounds.
- AR (Augmented Reality) navigation overlay.

**Speaker Notes:** 
"Looking ahead, we plan to implement real-time indoor positioning using BLE beacons, expand our map data to cover the entire university, and eventually introduce an AR navigation overlay for a true 'live view' experience."

---

## Slide 11: Q&A
**Title:** Thank You
**Visuals:** Team Photo or SyncUp Logo.
**Text:**
- Any Questions?
- Contact: xnuriey00@vutbr.cz

**Speaker Notes:** 
"Thank you for your time. We are incredibly proud of SyncUp, and we'd be happy to answer any questions you might have."
