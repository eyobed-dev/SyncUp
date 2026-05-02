import dotenv from "dotenv";
import { pb, withAdminAuth } from "../src/pocketbase.js";

dotenv.config();

async function getCollectionOrNull(name) {
  try {
    return await pb.collections.getOne(name);
  } catch (_) {
    return null;
  }
}

async function ensureCollection({ definition, requiredFieldNames }) {
  const existing = await getCollectionOrNull(definition.name);
  if (existing) {
    const existingMap = new Map((existing.fields || []).map((f) => [f.name, f]));
    const expectedMap = new Map((definition.fields || []).map((f) => [f.name, f]));
    const hasAllRequiredWithMatchingTypes = requiredFieldNames.every((name) => {
      const have = existingMap.get(name);
      const want = expectedMap.get(name);
      if (!have || !want) return false;
      return have.type === want.type;
    });
    if (hasAllRequiredWithMatchingTypes) return existing;

    const hasTypeMismatch = requiredFieldNames.some((name) => {
      const have = existingMap.get(name);
      const want = expectedMap.get(name);
      if (!have || !want) return false;
      return have.type !== want.type;
    });

    if (!hasTypeMismatch) {
      const mergedFields = [...(existing.fields || [])];
      for (const name of requiredFieldNames) {
        if (!existingMap.has(name) && expectedMap.has(name)) {
          mergedFields.push(expectedMap.get(name));
        }
      }
      return pb.collections.update(existing.id, {
        ...definition,
        fields: mergedFields,
      });
    }

    await pb.collections.delete(existing.id);
  }
  return pb.collections.create(definition);
}

function textField(name, { required = false, unique = false, max = 0 } = {}) {
  return {
    name,
    type: "text",
    required,
    unique,
    min: 0,
    max,
    pattern: "",
  };
}

function numberField(name, { required = false, min = null, max = null } = {}) {
  return {
    name,
    type: "number",
    required,
    min,
    max,
    noDecimal: true,
  };
}

function dateField(name, { required = false } = {}) {
  return {
    name,
    type: "date",
    required,
    min: "",
    max: "",
  };
}

function relationField(name, collectionId, { required = true } = {}) {
  return {
    name,
    type: "relation",
    required,
    collectionId,
    cascadeDelete: false,
    minSelect: required ? 1 : 0,
    maxSelect: 1,
    displayFields: [],
  };
}

async function ensureScheduleOwners() {
  return ensureCollection({
    definition: {
      name: "schedule_owners",
      type: "base",
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
      fields: [
        textField("external_id", { required: true, unique: true, max: 100 }),
        textField("name", { required: true, max: 200 }),
        textField("role", { max: 120 }),
        textField("department", { max: 200 }),
        textField("email", { max: 200 }),
      ],
    },
    requiredFieldNames: ["external_id", "name", "role", "department", "email"],
  });
}

async function ensureAppUsers() {
  return ensureCollection({
    definition: {
      name: "app_users",
      type: "base",
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
      fields: [
        textField("username", { required: true, unique: true, max: 80 }),
        textField("password", { required: true, max: 120 }),
        textField("role", { required: true, max: 40 }),
        textField("display_name", { required: true, max: 200 }),
        textField("owner_external_id", { max: 100 }),
        textField("discipline", { max: 120 }),
      ],
    },
    requiredFieldNames: [
      "username",
      "password",
      "role",
      "display_name",
      "owner_external_id",
      "discipline",
    ],
  });
}

async function ensureAvailabilityTemplates() {
  const owners = await pb.collections.getOne("schedule_owners");
  return ensureCollection({
    definition: {
      name: "availability_templates",
      type: "base",
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
      fields: [
        relationField("owner", owners.id),
        textField("template_id", { required: true, unique: true, max: 120 }),
        textField("days_after_monday", { required: true, max: 4 }),
        textField("start_hour", { required: true, max: 4 }),
        textField("start_minute", { required: true, max: 4 }),
        textField("duration_minutes", { required: true, max: 4 }),
        textField("title", { required: true, max: 200 }),
        textField("location", { max: 200 }),
        textField("meeting_link", { max: 500 }),
      ],
    },
    requiredFieldNames: [
      "owner",
      "template_id",
      "days_after_monday",
      "start_hour",
      "start_minute",
      "duration_minutes",
      "title",
      "location",
      "meeting_link",
    ],
  });
}

async function ensureBookings() {
  const owners = await pb.collections.getOne("schedule_owners");
  const templates = await pb.collections.getOne("availability_templates");
  return ensureCollection({
    definition: {
      name: "bookings",
      type: "base",
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
      fields: [
        relationField("owner", owners.id),
        relationField("template", templates.id, { required: false }),
        textField("owner_external_id", { required: true, max: 100 }),
        textField("participant_user_id", { max: 120 }),
        textField("source_slot_key", { required: true, unique: true, max: 240 }),
        textField("participant_name", { required: true, max: 200 }),
        textField("participant_email", { max: 200 }),
        textField("note", { max: 5000 }),
        textField("status", { required: true, max: 50 }),
        dateField("start_time", { required: true }),
        numberField("duration_minutes", { required: true, min: 5, max: 480 }),
        textField("title", { required: true, max: 200 }),
        textField("location", { max: 200 }),
        textField("meeting_link", { max: 500 }),
      ],
    },
    requiredFieldNames: [
      "owner",
      "template",
      "owner_external_id",
      "participant_user_id",
      "source_slot_key",
      "participant_name",
      "participant_email",
      "note",
      "status",
      "start_time",
      "duration_minutes",
      "title",
      "location",
      "meeting_link",
    ],
  });
}

async function ensureAvailabilitySlots() {
  const owners = await pb.collections.getOne("schedule_owners");
  return ensureCollection({
    definition: {
      name: "availability_slots",
      type: "base",
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
      fields: [
        relationField("owner", owners.id),
        textField("slot_id", { required: true, unique: true, max: 140 }),
        dateField("start_time", { required: true }),
        numberField("duration_minutes", { required: true, min: 5, max: 480 }),
        textField("title", { required: true, max: 200 }),
        textField("location", { max: 200 }),
        textField("meeting_link", { max: 500 }),
        textField("status", { required: true, max: 40 }),
      ],
    },
    requiredFieldNames: [
      "owner",
      "slot_id",
      "start_time",
      "duration_minutes",
      "title",
      "location",
      "meeting_link",
      "status",
    ],
  });
}

async function ensureRecurringMeetings() {
  return ensureCollection({
    definition: {
      name: "recurring_meetings",
      type: "base",
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
      fields: [
        textField("meeting_id", { required: true, unique: true, max: 120 }),
        textField("owner_external_id", { required: true, max: 100 }),
        textField("participant_name", { required: true, max: 200 }),
        textField("student_id", { max: 100 }),
        textField("days_after_monday", { required: true, max: 4 }),
        textField("start_hour", { required: true, max: 4 }),
        textField("start_minute", { required: true, max: 4 }),
        textField("duration_minutes", { required: true, max: 4 }),
        textField("discipline", { max: 120 }),
        textField("topic", { max: 200 }),
        textField("location", { max: 200 }),
      ],
    },
    requiredFieldNames: [
      "meeting_id",
      "owner_external_id",
      "participant_name",
      "student_id",
      "days_after_monday",
      "start_hour",
      "start_minute",
      "duration_minutes",
      "discipline",
      "topic",
      "location",
    ],
  });
}

async function ensureSessions() {
  return ensureCollection({
    definition: {
      name: "sessions",
      type: "base",
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
      fields: [
        textField("session_id", { required: true, unique: true, max: 140 }),
        textField("participant_name", { required: true, max: 200 }),
        textField("student_id", { max: 100 }),
        dateField("start_time", { required: true }),
        numberField("duration_minutes", { required: true, min: 5, max: 480 }),
        textField("discipline", { max: 120 }),
        textField("topic", { max: 200 }),
        textField("location", { max: 200 }),
        textField("minutes", { max: 12000 }),
        textField("deliberations", { max: 12000 }),
        textField("meeting_status", { max: 40 }),
      ],
    },
    requiredFieldNames: [
      "session_id",
      "participant_name",
      "student_id",
      "start_time",
      "duration_minutes",
      "discipline",
      "topic",
      "location",
      "minutes",
      "deliberations",
      "meeting_status",
    ],
  });
}

async function ensureMeetingStatusEvents() {
  return ensureCollection({
    definition: {
      name: "meeting_status_events",
      type: "base",
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
      fields: [
        textField("event_key", { required: true, unique: true, max: 260 }),
        textField("owner_external_id", { required: true, max: 100 }),
        textField("meeting_id", { required: true, max: 120 }),
        dateField("meeting_start_time", { required: true }),
        textField("student_id", { max: 120 }),
        textField("participant_name", { max: 220 }),
        textField("status", { required: true, max: 40 }),
        textField("note", { max: 2000 }),
      ],
    },
    requiredFieldNames: [
      "event_key",
      "owner_external_id",
      "meeting_id",
      "meeting_start_time",
      "student_id",
      "participant_name",
      "status",
      "note",
    ],
  });
}

async function main() {
  await withAdminAuth(async () => {
    await ensureScheduleOwners();
    await ensureAppUsers();
    await ensureAvailabilityTemplates();
    await ensureAvailabilitySlots();
    await ensureRecurringMeetings();
    await ensureSessions();
    await ensureMeetingStatusEvents();
    await ensureBookings();
  });
  // eslint-disable-next-line no-console
  console.log(
    "Collections ensured: schedule_owners, app_users, availability_templates, availability_slots, recurring_meetings, sessions, meeting_status_events, bookings",
  );
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});

