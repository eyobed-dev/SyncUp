# SyncUp PocketBase API

Lightweight backend for SyncUp using:

- PocketBase (self-hosted DB + admin auth)
- Express API (app-facing endpoints)

## What this provides

- `GET /api/v1/owners`
- `GET /api/v1/owners/:ownerId/availability?weekStart=YYYY-MM-DD`
- `POST /api/v1/bookings`
- `POST /api/v1/owners/:ownerId/templates/bulk`
- `POST /api/v1/owners/:ownerId/availability/slots/bulk`
- `GET /api/v1/meetings?weekStart=YYYY-MM-DD&ownerId=p1`
- `POST /api/v1/meetings/status` (happened, late, postponed, cancelled)
- `GET /api/v1/sessions/prior?studentId=...` (or `participantName=...`)
- `GET /health`

The API is designed to mirror your current Flutter flows:

- Find schedule owners
- Get weekly open slots
- Book a slot
- Create availability templates

## 1) Run locally (without Docker)

1. Start PocketBase (any way you prefer) at `http://127.0.0.1:8090`.
2. Create your PocketBase superuser in the PocketBase admin UI.
3. In this folder:

```bash
cp .env.example .env
npm install
npm run bootstrap
npm run seed
npm run dev
```

## 2) Run with Docker Compose

1. Create `.env` in this folder:

```env
POCKETBASE_SUPERUSER_EMAIL=admin@example.com
POCKETBASE_SUPERUSER_PASSWORD=change-me-now
```

2. Start services:

```bash
docker compose up -d --build
```

3. Open PocketBase UI at `http://localhost:8090/_/`.
4. If no superuser exists yet, create one from the UI.
5. Then bootstrap and seed from host shell:

```bash
npm install
npm run bootstrap
npm run seed
```

### If login says invalid credentials

When using Docker, PocketBase serves from `/pb_data`.  
If you reset users via CLI, include the same data dir:

```bash
docker exec syncup-pocketbase /pb/pocketbase --dir=/pb_data superuser upsert admin@syncup.com Admin123
```

## Data model

Collections created by `npm run bootstrap`:

- `schedule_owners`
  - `external_id` (unique)
  - `name`, `role`, `department`, `email`
- `availability_templates`
  - `owner` relation -> `schedule_owners`
  - `template_id` (unique)
  - `days_after_monday`, `start_hour`, `start_minute`, `duration_minutes`
  - `title`, `location`
- `bookings`
  - `owner` relation -> `schedule_owners`
  - `template` relation -> `availability_templates`
  - `source_slot_key` (unique, prevents double booking)
  - participant + slot snapshot fields
- `availability_slots` (date-specific slots created from Add Schedule)
- `recurring_meetings` (Home week schedule)
- `sessions` (prior meeting history/minutes)
- `meeting_status_events` (status per concrete meeting occurrence)

## Booking conflict rule

`source_slot_key` is unique:

`<ownerExternalId>:<weekStartDate>:<templateId>`

If the same slot is booked twice, the second request fails with `409`.

## API examples

### List owners

```bash
curl "http://localhost:8080/api/v1/owners"
```

### List weekly availability

```bash
curl "http://localhost:8080/api/v1/owners/p1/availability?weekStart=2026-05-03"
```

### Book a slot

```bash
curl -X POST "http://localhost:8080/api/v1/bookings" \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "p1",
    "templateId": "p1-w1-4",
    "weekStart": "2026-05-03",
    "participantName": "Jane Student",
    "participantEmail": "jane@example.com",
    "note": "Need help with mentoring topic"
  }'
```

### Bulk create templates

```bash
curl -X POST "http://localhost:8080/api/v1/owners/p1/templates/bulk" \
  -H "Content-Type: application/json" \
  -d '{
    "templates": [
      {
        "templateId": "p1-custom-1",
        "daysAfterMonday": 2,
        "startHour": 14,
        "startMinute": 30,
        "durationMinutes": 30,
        "title": "Consultation",
        "location": "Room B109"
      }
    ]
  }'
```

## Integrating into Flutter

Replace current seed-backed data calls with HTTP calls:

- `getScheduleOwners()` -> `GET /api/v1/owners`
- `getAvailabilityForOwner(ownerId, weekStart)` -> `GET /availability`
- booking confirmation -> `POST /api/v1/bookings`

Keep local/UI state the same while swapping only the data source layer.

