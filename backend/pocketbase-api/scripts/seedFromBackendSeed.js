import fs from "node:fs/promises";
import path from "node:path";
import dotenv from "dotenv";
import crypto from "node:crypto";
import { withAdminAuth, pb } from "../src/pocketbase.js";

dotenv.config();
const SCRYPT_N = Number(process.env.PASSWORD_HASH_N || 16384);
const SCRYPT_R = Number(process.env.PASSWORD_HASH_R || 8);
const SCRYPT_P = Number(process.env.PASSWORD_HASH_P || 1);
// Keep under app_users.password max length (120 chars in collection schema).
const SCRYPT_KEYLEN = Number(process.env.PASSWORD_HASH_KEYLEN || 32);

async function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString("hex");
  const derived = crypto.scryptSync(String(password), salt, SCRYPT_KEYLEN, {
    N: SCRYPT_N,
    r: SCRYPT_R,
    p: SCRYPT_P,
  });
  return `scrypt$${SCRYPT_N}$${SCRYPT_R}$${SCRYPT_P}$${salt}$${derived.toString("hex")}`;
}

async function readBackendSeed() {
  const root = path.resolve(process.cwd(), "../..");
  const file = path.join(root, "assets", "data", "backend_seed.json");
  const raw = await fs.readFile(file, "utf8");
  return JSON.parse(raw);
}

async function ensureOwner(owner) {
  const escaped = owner.id.replace(/"/g, '\\"');
  try {
    return await pb
      .collection("schedule_owners")
      .getFirstListItem(`external_id="${escaped}"`);
  } catch {
    return pb.collection("schedule_owners").create({
      external_id: owner.id,
      name: owner.name,
      role: owner.role || "",
      department: owner.department || "",
      email: owner.email || "",
    });
  }
}

async function ensureTemplate(ownerRecordId, slot) {
  const escaped = slot.id.replace(/"/g, '\\"');
  try {
    return await pb
      .collection("availability_templates")
      .getFirstListItem(`template_id="${escaped}"`);
  } catch {
    return pb.collection("availability_templates").create({
      owner: ownerRecordId,
      template_id: slot.id,
      days_after_monday: String(Number(slot.daysAfterMonday)),
      start_hour: String(Number(slot.startHour)),
      start_minute: String(Number(slot.startMinute)),
      duration_minutes: String(Number(slot.durationMinutes)),
      title: slot.title,
      location: slot.location || "",
      meeting_link: slot.meetingLink || "",
    });
  }
}

async function ensureRecurringMeeting(meeting) {
  const escaped = String(meeting.id).replace(/"/g, '\\"');
  try {
    return await pb
      .collection("recurring_meetings")
      .getFirstListItem(`meeting_id="${escaped}"`);
  } catch {
    return pb.collection("recurring_meetings").create({
      meeting_id: String(meeting.id),
      owner_external_id: "p1",
      participant_name: meeting.participantName,
      student_id: meeting.studentId || "",
      days_after_monday: String(Number(meeting.daysAfterMonday)),
      start_hour: String(Number(meeting.startHour)),
      start_minute: String(Number(meeting.startMinute)),
      duration_minutes: String(Number(meeting.durationMinutes)),
      discipline: meeting.discipline || "",
      topic: meeting.topic || "",
      location: meeting.location || "",
    });
  }
}

async function ensureSession(session) {
  const escaped = String(session.id).replace(/"/g, '\\"');
  try {
    return await pb
      .collection("sessions")
      .getFirstListItem(`session_id="${escaped}"`);
  } catch {
    return pb.collection("sessions").create({
      session_id: String(session.id),
      owner_external_id: session.ownerExternalId || "p1",
      participant_name: session.participantName,
      student_id: session.studentId || "",
      start_time: session.startTime,
      duration_minutes: String(Number(session.durationMinutes)),
      discipline: session.discipline || "",
      topic: session.topic || "",
      location: session.location || "",
      minutes: session.minutes || "",
      deliberations: session.deliberations || "",
      shared_documents: Array.isArray(session.sharedDocuments)
        ? JSON.stringify(session.sharedDocuments)
        : "[]",
      meeting_status: session.meetingStatus || "",
    });
  }
}

async function ensureAppUser(user) {
  const hashedPassword = await hashPassword(user.password);
  const escaped = String(user.username).replace(/"/g, '\\"');
  try {
    const existing = await pb
      .collection("app_users")
      .getFirstListItem(`username="${escaped}"`);
    return pb.collection("app_users").update(existing.id, {
      username: String(user.username),
      password: hashedPassword,
      role: String(user.role),
      display_name: String(user.displayName),
      owner_external_id: user.ownerExternalId ? String(user.ownerExternalId) : "",
      discipline: user.discipline ? String(user.discipline) : "",
    });
  } catch {
    return pb.collection("app_users").create({
      username: String(user.username),
      password: hashedPassword,
      role: String(user.role),
      display_name: String(user.displayName),
      owner_external_id: user.ownerExternalId ? String(user.ownerExternalId) : "",
      discipline: user.discipline ? String(user.discipline) : "",
    });
  }
}

function slugify(value) {
  return String(value)
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ".")
    .replace(/^\.+|\.+$/g, "")
    .slice(0, 40);
}

function createUniqueUsername(base, used) {
  const normalizedBase = slugify(base) || "user";
  if (!used.has(normalizedBase)) {
    used.add(normalizedBase);
    return normalizedBase;
  }
  let idx = 2;
  while (used.has(`${normalizedBase}${idx}`)) {
    idx += 1;
  }
  const username = `${normalizedBase}${idx}`;
  used.add(username);
  return username;
}

async function main() {
  const seed = await readBackendSeed();
  const owners = Array.isArray(seed.scheduleOwners) ? seed.scheduleOwners : [];
  const availabilityByOwnerId = seed.availabilityByOwnerId || {};
  const meetings = Array.isArray(seed.meetings) ? seed.meetings : [];
  const sessions = Array.isArray(seed.sessions) ? seed.sessions : [];
  const disciplineByStudentId = new Map();
  const disciplineByStudentName = new Map();

  const rememberDiscipline = (studentId, participantName, discipline) => {
    const d = String(discipline || "").trim();
    if (!d) return;
    const sid = String(studentId || "").trim();
    const pname = String(participantName || "").trim().toLowerCase();
    if (sid) disciplineByStudentId.set(sid, d);
    if (pname) disciplineByStudentName.set(pname, d);
  };
  for (const meeting of meetings) {
    rememberDiscipline(meeting.studentId, meeting.participantName, meeting.discipline);
  }
  for (const session of sessions) {
    rememberDiscipline(session.studentId, session.participantName, session.discipline);
  }

  let ownerCount = 0;
  let templateCount = 0;
  let meetingCount = 0;
  let sessionCount = 0;
  let appUserCount = 0;

  await withAdminAuth(async () => {
    for (const owner of owners) {
      const ownerRecord = await ensureOwner(owner);
      ownerCount += 1;

      const slots = Array.isArray(availabilityByOwnerId[owner.id])
        ? availabilityByOwnerId[owner.id]
        : [];
      for (const slot of slots) {
        await ensureTemplate(ownerRecord.id, slot);
        templateCount += 1;
      }
    }

    for (const meeting of meetings) {
      await ensureRecurringMeeting(meeting);
      meetingCount += 1;
    }

    for (const session of sessions) {
      await ensureSession(session);
      sessionCount += 1;
    }

    const defaultUsers = [
      {
        username: "p",
        password: "1",
        role: "owner",
        displayName: "Prof. Alexander Meduna",
        ownerExternalId: "p1",
        discipline: "",
      },
      {
        username: "s",
        password: "1",
        role: "attendee",
        displayName: "Liam Carter",
        ownerExternalId: "",
        discipline:
          disciplineByStudentName.get("liam carter") ||
          disciplineByStudentId.get("g88wkjy7830ciqi") ||
          "BSc",
      },
    ];

    const appUsers = [];
    const usedUsernames = new Set();
    for (const user of defaultUsers) {
      appUsers.push(user);
      usedUsernames.add(user.username);
    }

    const ownerByName = new Map(
      owners.map((o) => [String(o.name).trim().toLowerCase(), o]),
    );

    for (const owner of owners) {
      if (owner.id === "p1") continue; // mapped to default "professor"
      const username = createUniqueUsername(owner.name, usedUsernames);
      appUsers.push({
        username,
        password: "Owner@123",
        role: "owner",
        displayName: owner.name,
        ownerExternalId: owner.id,
        discipline: "",
      });
    }

    const attendeeNames = new Set();
    for (const meeting of meetings) {
      const name = String(meeting.participantName || "").trim();
      if (name) attendeeNames.add(name);
    }
    for (const session of sessions) {
      const name = String(session.participantName || "").trim();
      if (name) attendeeNames.add(name);
    }
    attendeeNames.delete("Liam Carter"); // mapped to default "student"

    for (const name of attendeeNames) {
      const owner = ownerByName.get(name.toLowerCase());
      if (owner) continue; // already represented as owner account
      const username = createUniqueUsername(name, usedUsernames);
      appUsers.push({
        username,
        password: "Student@123",
        role: "attendee",
        displayName: name,
        ownerExternalId: "",
        discipline: disciplineByStudentName.get(name.toLowerCase()) || "",
      });
    }

    for (const user of appUsers) {
      await ensureAppUser(user);
      appUserCount += 1;
    }
  });

  // eslint-disable-next-line no-console
  console.log(
    `Seed complete. Owners: ${ownerCount}, templates: ${templateCount}, recurring meetings: ${meetingCount}, sessions: ${sessionCount}, app users: ${appUserCount}`,
  );
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});

