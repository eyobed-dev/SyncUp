/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Node.js Express backend proxy and PocketBase integration logic.
 */

import dotenv from "dotenv";
import cors from "cors";
import express from "express";
import crypto from "node:crypto";
import { pb, withAdminAuth } from "./pocketbase.js";

dotenv.config();

const app = express();
app.use(
  cors({
    origin: true,
    credentials: true,
  }),
);
app.use(express.json({ limit: "1mb" }));

const PORT = Number(process.env.PORT || 8080);
const DAY_MS = 24 * 60 * 60 * 1000;
const SCRYPT_N = Number(process.env.PASSWORD_HASH_N || 16384);
const SCRYPT_R = Number(process.env.PASSWORD_HASH_R || 8);
const SCRYPT_P = Number(process.env.PASSWORD_HASH_P || 1);
// Keep under app_users.password max length (120 chars in collection schema).
const SCRYPT_KEYLEN = Number(process.env.PASSWORD_HASH_KEYLEN || 32);

function isScryptHash(value) {
  return String(value || "").startsWith("scrypt$");
}

async function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString("hex");
  const derived = crypto.scryptSync(String(password), salt, SCRYPT_KEYLEN, {
    N: SCRYPT_N,
    r: SCRYPT_R,
    p: SCRYPT_P,
  });
  return `scrypt$${SCRYPT_N}$${SCRYPT_R}$${SCRYPT_P}$${salt}$${derived.toString("hex")}`;
}

function verifyScryptHash(candidate, storedPassword) {
  const [algo, n, r, p, salt, hashHex] = String(storedPassword || "").split("$");
  if (algo !== "scrypt" || !salt || !hashHex) return false;
  const expected = Buffer.from(hashHex, "hex");
  if (!expected.length) return false;
  const actual = crypto.scryptSync(String(candidate), salt, expected.length, {
    N: Number(n),
    r: Number(r),
    p: Number(p),
  });
  if (actual.length !== expected.length) return false;
  return crypto.timingSafeEqual(actual, expected);
}

async function verifyPassword(candidate, storedPassword) {
  const stored = String(storedPassword || "");
  if (!stored) return false;
  if (isScryptHash(stored)) {
    return verifyScryptHash(candidate, stored);
  }
  return stored === String(candidate);
}

function normalizeDateOnly(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function mondayFromWeekStart(weekStart) {
  return new Date(weekStart.getTime() + DAY_MS);
}

function slotDateTime(weekStart, template) {
  const monday = mondayFromWeekStart(weekStart);
  return new Date(
    Date.UTC(
      monday.getUTCFullYear(),
      monday.getUTCMonth(),
      monday.getUTCDate() + Number(template.days_after_monday || 0),
      Number(template.start_hour || 0),
      Number(template.start_minute || 0),
      0,
      0,
    ),
  );
}

function makeSourceSlotKey(ownerExternalId, weekStartDate, templateId) {
  const weekLabel = weekStartDate.toISOString().slice(0, 10);
  return `${ownerExternalId}:${weekLabel}:${templateId}`;
}

function makeConcreteSlotKey(ownerExternalId, slotId) {
  return `${ownerExternalId}:slot:${slotId}`;
}

function makeMeetingEventKey(meetingId, startTime) {
  return `${meetingId}|${new Date(startTime).toISOString()}`;
}

function makeSessionLookupKey({ ownerExternalId, studentId, participantName, startTime }) {
  const owner = String(ownerExternalId || "").trim();
  const sid = String(studentId || "").trim();
  const pname = String(participantName || "").trim().toLowerCase();
  const iso = new Date(startTime).toISOString();
  return `${owner || "-"}|${sid || "-"}|${pname || "-"}|${iso}`;
}

function parseSharedDocuments(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => {
        if (typeof item === "string") {
          const trimmed = item.trim();
          return trimmed ? { title: "", url: trimmed } : null;
        }
        if (item && typeof item === "object") {
          const title = String(item.title || "").trim();
          const url = String(item.url || "").trim();
          return url ? { title, url } : null;
        }
        return null;
      })
      .filter(Boolean);
  }
  const raw = String(value || "").trim();
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parseSharedDocuments(parsed);
  } catch (_) {
    return [];
  }
}

function stringifySharedDocuments(value) {
  return JSON.stringify(parseSharedDocuments(value));
}

async function getOwnerByExternalId(ownerExternalId) {
  const escaped = ownerExternalId.replace(/"/g, '\\"');
  return pb
    .collection("schedule_owners")
    .getFirstListItem(`external_id="${escaped}"`);
}

async function getAppUserByUsername(username) {
  const escaped = String(username).replace(/"/g, '\\"');
  return pb.collection("app_users").getFirstListItem(`username="${escaped}"`);
}

async function getAppUserById(userId) {
  return pb.collection("app_users").getOne(String(userId));
}

function normalizeDiscipline(value) {
  const out = String(value || "").trim();
  return out || null;
}

function buildUserDisciplineMaps(rows) {
  const byId = new Map();
  const byName = new Map();
  for (const row of rows) {
    const discipline = normalizeDiscipline(row.discipline);
    if (!discipline) continue;
    const id = String(row.id || "").trim();
    const displayName = String(row.display_name || "").trim().toLowerCase();
    if (id) byId.set(id, discipline);
    if (displayName) byName.set(displayName, discipline);
  }
  return { byId, byName };
}

function resolveStudentDiscipline({
  disciplineByUserId,
  disciplineByDisplayName,
  studentId,
  participantName,
  fallbackDiscipline = null,
}) {
  const sid = String(studentId || "").trim();
  if (sid && disciplineByUserId.has(sid)) {
    return disciplineByUserId.get(sid);
  }
  const pname = String(participantName || "").trim().toLowerCase();
  if (pname && disciplineByDisplayName.has(pname)) {
    return disciplineByDisplayName.get(pname);
  }
  return normalizeDiscipline(fallbackDiscipline);
}

app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true, service: "syncup-pocketbase-api" });
});

app.get("/api/v1/owners", async (_req, res) => {
  try {
    const items = await withAdminAuth(() =>
      pb.collection("schedule_owners").getFullList(),
    );

    const owners = items.map((item) => ({
      id: item.external_id,
      name: item.name,
      role: item.role || null,
      department: item.department || null,
      email: item.email || null,
    }));
    owners.sort((a, b) => a.name.localeCompare(b.name));

    res.status(200).json({ owners });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch owners", details: String(error) });
  }
});

app.post("/api/v1/auth/login", async (req, res) => {
  try {
    const username = String(req.body?.username || "").trim().toLowerCase();
    const password = String(req.body?.password || "");
    if (!username || !password) {
      return res.status(400).json({ error: "username and password are required" });
    }

    const user = await withAdminAuth(() => getAppUserByUsername(username));
    if (!user) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const currentStoredPassword = String(user.password || "");
    const validPassword = await verifyPassword(password, currentStoredPassword);
    if (!validPassword) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Seamlessly migrate legacy plaintext passwords to scrypt after successful login.
    if (!isScryptHash(currentStoredPassword)) {
      try {
        const nextHashedPassword = await hashPassword(password);
        await withAdminAuth(() =>
          pb.collection("app_users").update(user.id, { password: nextHashedPassword }),
        );
      } catch (_) {
        // Best-effort migration; do not block successful login.
      }
    }

    return res.status(200).json({
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
        displayName: user.display_name,
        ownerId: user.owner_external_id || null,
        discipline: normalizeDiscipline(user.discipline),
      },
    });
  } catch (_) {
    return res.status(401).json({ error: "Invalid credentials" });
  }
});

app.get("/api/v1/users", async (_req, res) => {
  try {
    const rows = await withAdminAuth(() => pb.collection("app_users").getFullList());
    const users = rows
      .map((u) => ({
        id: u.id,
        username: u.username,
        role: u.role,
        displayName: u.display_name,
        ownerId: u.owner_external_id || null,
        discipline: normalizeDiscipline(u.discipline),
      }))
      .sort((a, b) => a.displayName.localeCompare(b.displayName));
    return res.status(200).json({ users });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch users", details: String(error) });
  }
});

app.get("/api/v1/owners/:ownerId/availability", async (req, res) => {
  try {
    const weekStart = normalizeDateOnly(req.query.weekStart);
    if (!weekStart) {
      return res
        .status(400)
        .json({ error: "weekStart query param is required (ISO date)" });
    }

    const ownerId = req.params.ownerId;

    const owner = await withAdminAuth(() => getOwnerByExternalId(ownerId));
    const templateFilter = `owner="${owner.id}"`;
    const templates = await withAdminAuth(() =>
      pb.collection("availability_templates").getFullList({
        filter: templateFilter,
      }),
    );

    const bookingStart = weekStart.toISOString();
    const bookingEnd = new Date(weekStart.getTime() + DAY_MS * 7).toISOString();
    const escapedOwnerId = ownerId.replace(/"/g, '\\"');
    const bookingFilter =
      `owner_external_id="${escapedOwnerId}"` +
      ` && start_time >= "${bookingStart}"` +
      ` && start_time < "${bookingEnd}"` +
      ` && status = "confirmed"`;
    const bookings = await withAdminAuth(() =>
      pb.collection("bookings").getFullList({
        filter: bookingFilter,
      }),
    );

    const bookedSlotKeys = new Set(bookings.map((b) => b.source_slot_key));

    const templateSlots = templates
      .map((template) => {
        const startsAt = slotDateTime(weekStart, template);
        const sourceSlotKey = makeSourceSlotKey(owner.external_id, weekStart, template.template_id);
        return {
          id: template.template_id,
          startTime: startsAt.toISOString(),
          durationMinutes: Number(template.duration_minutes),
          title: template.title,
          location: template.location || null,
          meetingLink: template.meeting_link || null,
          booked: bookedSlotKeys.has(sourceSlotKey),
        };
      })
      .filter((slot) => !slot.booked);

    const concreteFilter =
      `owner="${owner.id}"` +
      ` && start_time >= "${bookingStart}"` +
      ` && start_time < "${bookingEnd}"` +
      ` && status = "open"`;
    const concreteSlots = await withAdminAuth(() =>
      pb.collection("availability_slots").getFullList({
        filter: concreteFilter,
      }),
    );

    const concreteMapped = concreteSlots
      .map((slot) => {
        const sourceSlotKey = makeConcreteSlotKey(owner.external_id, slot.slot_id);
        return {
          id: slot.slot_id,
          startTime: new Date(slot.start_time).toISOString(),
          durationMinutes: Number(slot.duration_minutes),
          title: slot.title,
          location: slot.location || null,
          meetingLink: slot.meeting_link || null,
          booked: bookedSlotKeys.has(sourceSlotKey),
        };
      })
      .filter((slot) => !slot.booked);

    const slots = [...templateSlots, ...concreteMapped].sort((a, b) =>
      a.startTime.localeCompare(b.startTime),
    );

    return res.status(200).json({
      owner: {
        id: owner.external_id,
        name: owner.name,
        role: owner.role || null,
      },
      weekStart: weekStart.toISOString().slice(0, 10),
      slots,
    });
  } catch (error) {
    if (String(error).includes("404")) {
      return res.status(404).json({ error: "Owner not found" });
    }
    return res
      .status(500)
      .json({ error: "Failed to fetch availability", details: String(error) });
  }
});

app.post("/api/v1/bookings", async (req, res) => {
  try {
    const {
      ownerId,
      templateId,
      slotId,
      weekStart,
      participantName,
      participantUserId,
      participantEmail,
      note,
      sharedDocuments,
    } = req.body ?? {};

    if (!ownerId || (!templateId && !slotId) || !weekStart || !participantName) {
      return res.status(400).json({
        error:
          "Missing required fields: ownerId, (templateId or slotId), weekStart, participantName",
      });
    }

    const normalizedWeekStart = normalizeDateOnly(weekStart);
    if (!normalizedWeekStart) {
      return res.status(400).json({ error: "Invalid weekStart date" });
    }

    const owner = await withAdminAuth(() => getOwnerByExternalId(ownerId));

    let startTime;
    let sourceSlotKey;
    let template = null;
    let concreteSlot = null;
    if (templateId) {
      const escapedTemplateId = String(templateId).replace(/"/g, '\\"');
      template = await withAdminAuth(() =>
        pb
          .collection("availability_templates")
          .getFirstListItem(`owner="${owner.id}" && template_id="${escapedTemplateId}"`),
      );
      startTime = slotDateTime(normalizedWeekStart, template);
      sourceSlotKey = makeSourceSlotKey(
        owner.external_id,
        normalizedWeekStart,
        template.template_id,
      );
    } else {
      const escapedSlotId = String(slotId).replace(/"/g, '\\"');
      try {
        template = await withAdminAuth(() =>
          pb
            .collection("availability_templates")
            .getFirstListItem(`owner="${owner.id}" && template_id="${escapedSlotId}"`),
        );
      } catch (_) {
        template = null;
      }
      if (template) {
        startTime = slotDateTime(normalizedWeekStart, template);
        sourceSlotKey = makeSourceSlotKey(
          owner.external_id,
          normalizedWeekStart,
          template.template_id,
        );
      } else {
        concreteSlot = await withAdminAuth(() =>
          pb
            .collection("availability_slots")
            .getFirstListItem(
              `owner="${owner.id}" && slot_id="${escapedSlotId}" && status="open"`,
            ),
        );
        startTime = new Date(concreteSlot.start_time);
        sourceSlotKey = makeConcreteSlotKey(owner.external_id, concreteSlot.slot_id);
      }
    }

    if (participantUserId) {
      try {
        await withAdminAuth(() => getAppUserById(participantUserId));
      } catch (_) {
        return res.status(400).json({ error: "Invalid participantUserId" });
      }
    }

    const record = {
      owner: owner.id,
      owner_external_id: owner.external_id,
      participant_user_id: participantUserId ? String(participantUserId).trim() : "",
      source_slot_key: sourceSlotKey,
      participant_name: String(participantName).trim(),
      participant_email: participantEmail ? String(participantEmail).trim() : "",
      note: note ? String(note).trim() : "",
      shared_documents: stringifySharedDocuments(sharedDocuments),
      status: "confirmed",
      start_time: startTime.toISOString(),
      duration_minutes: Number(
        template ? template.duration_minutes : concreteSlot.duration_minutes,
      ),
      title: template ? template.title : concreteSlot.title,
      location: template ? template.location || "" : concreteSlot.location || "",
      meeting_link: template
        ? template.meeting_link || ""
        : concreteSlot.meeting_link || "",
    };
    if (template?.id) {
      record.template = template.id;
    }

    const created = await withAdminAuth(() => pb.collection("bookings").create(record));

    if (concreteSlot) {
      await withAdminAuth(() =>
        pb.collection("availability_slots").update(concreteSlot.id, { status: "booked" }),
      );
    }

    return res.status(201).json({
      booking: {
        id: created.id,
        ownerId: owner.external_id,
        slotId: slotId || template.template_id,
        startTime: created.start_time,
        durationMinutes: created.duration_minutes,
        title: created.title,
        location: created.location || null,
        meetingLink: created.meeting_link || null,
        participantName: created.participant_name,
        participantEmail: created.participant_email || null,
        note: created.note || null,
        sharedDocuments: parseSharedDocuments(created.shared_documents),
      },
    });
  } catch (error) {
    const details = String(error);
    if (details.includes("source_slot_key")) {
      return res.status(409).json({ error: "Slot already booked" });
    }
    if (details.includes("404")) {
      return res.status(404).json({ error: "Owner or slot template not found" });
    }
    return res.status(500).json({ error: "Failed to book slot", details });
  }
});

app.post("/api/v1/bookings/:bookingId/cancel", async (req, res) => {
  try {
    const bookingId = String(req.params.bookingId || "").trim();
    const participantUserId = String(req.body?.participantUserId || "").trim();
    const participantName = String(req.body?.participantName || "").trim();
    const cancelReason = String(req.body?.cancelReason || "").trim();

    if (!bookingId) {
      return res.status(400).json({ error: "bookingId is required" });
    }
    if (!participantUserId && !participantName) {
      return res
        .status(400)
        .json({ error: "participantUserId or participantName is required" });
    }

    const booking = await withAdminAuth(() =>
      pb.collection("bookings").getOne(bookingId),
    );
    if (!booking) {
      return res.status(404).json({ error: "Booking not found" });
    }
    if (String(booking.status || "").toLowerCase() !== "confirmed") {
      return res.status(409).json({ error: "Booking is not active" });
    }

    const bookingUserId = String(booking.participant_user_id || "").trim();
    const bookingName = String(booking.participant_name || "").trim().toLowerCase();
    const reqName = participantName.toLowerCase();
    const isOwnerByUserId =
      participantUserId && bookingUserId && participantUserId === bookingUserId;
    const isOwnerByName = !participantUserId && participantName && bookingName === reqName;
    if (!isOwnerByUserId && !isOwnerByName) {
      return res
        .status(403)
        .json({ error: "Booking does not belong to the requesting participant" });
    }

    const nextNote = cancelReason
      ? [String(booking.note || "").trim(), `Student cancellation reason: ${cancelReason}`]
          .filter(Boolean)
          .join("\n\n")
      : String(booking.note || "");

    const updated = await withAdminAuth(() =>
      pb.collection("bookings").update(booking.id, {
        status: "cancelled",
        note: nextNote,
      }),
    );

    // Re-open concrete slots when cancellations free a one-off slot.
    const sourceSlotKey = String(booking.source_slot_key || "");
    if (sourceSlotKey.includes(":slot:")) {
      const slotId = sourceSlotKey.split(":slot:")[1] || "";
      if (slotId) {
        try {
          const escapedSlotId = slotId.replace(/"/g, '\\"');
          const slot = await withAdminAuth(() =>
            pb
              .collection("availability_slots")
              .getFirstListItem(
                `owner="${booking.owner}" && slot_id="${escapedSlotId}"`,
              ),
          );
          await withAdminAuth(() =>
            pb.collection("availability_slots").update(slot.id, { status: "open" }),
          );
        } catch (_) {
          // Best effort only; cancelled booking still persists.
        }
      }
    }

    return res.status(200).json({
      booking: {
        id: updated.id,
        status: updated.status,
        note: updated.note || null,
      },
    });
  } catch (error) {
    const details = String(error);
    if (details.includes("404")) {
      return res.status(404).json({ error: "Booking not found" });
    }
    return res.status(500).json({ error: "Failed to cancel booking", details });
  }
});

app.post("/api/v1/owners/:ownerId/templates/bulk", async (req, res) => {
  try {
    const ownerId = req.params.ownerId;
    const templates = Array.isArray(req.body?.templates) ? req.body.templates : [];
    if (templates.length === 0) {
      return res.status(400).json({ error: "templates[] is required" });
    }

    const owner = await withAdminAuth(() => getOwnerByExternalId(ownerId));

    const created = [];
    for (const t of templates) {
      if (
        !t.templateId ||
        typeof t.daysAfterMonday !== "number" ||
        typeof t.startHour !== "number" ||
        typeof t.startMinute !== "number" ||
        typeof t.durationMinutes !== "number" ||
        !t.title
      ) {
        return res.status(400).json({
          error:
            "Each template must include templateId, daysAfterMonday, startHour, startMinute, durationMinutes, title",
        });
      }

      const payload = {
        owner: owner.id,
        template_id: String(t.templateId),
        days_after_monday: String(Number(t.daysAfterMonday)),
        start_hour: String(Number(t.startHour)),
        start_minute: String(Number(t.startMinute)),
        duration_minutes: String(Number(t.durationMinutes)),
        title: String(t.title),
        location: t.location ? String(t.location) : "",
        meeting_link: t.meetingLink ? String(t.meetingLink).trim() : "",
      };

      const row = await withAdminAuth(() =>
        pb.collection("availability_templates").create(payload),
      );
      created.push({
        id: row.id,
        templateId: row.template_id,
      });
    }

    return res.status(201).json({ ownerId, createdCount: created.length, created });
  } catch (error) {
    const details = String(error);
    if (details.includes("template_id")) {
      return res
        .status(409)
        .json({ error: "One or more templateId values already exist" });
    }
    if (details.includes("404")) {
      return res.status(404).json({ error: "Owner not found" });
    }
    return res
      .status(500)
      .json({ error: "Failed to create templates", details: String(error) });
  }
});

app.post("/api/v1/owners/:ownerId/availability/slots/bulk", async (req, res) => {
  try {
    const ownerId = req.params.ownerId;
    const slots = Array.isArray(req.body?.slots) ? req.body.slots : [];
    if (slots.length === 0) {
      return res.status(400).json({ error: "slots[] is required" });
    }
    const owner = await withAdminAuth(() => getOwnerByExternalId(ownerId));
    const created = [];
    for (const slot of slots) {
      if (
        !slot.slotId ||
        !slot.startTime ||
        typeof slot.durationMinutes !== "number" ||
        !slot.title
      ) {
        return res.status(400).json({
          error:
            "Each slot must include slotId, startTime, durationMinutes, and title",
        });
      }
      const payload = {
        owner: owner.id,
        slot_id: String(slot.slotId),
        start_time: String(slot.startTime),
        duration_minutes: String(Number(slot.durationMinutes)),
        title: String(slot.title),
        location: slot.location ? String(slot.location) : "",
        meeting_link: slot.meetingLink ? String(slot.meetingLink).trim() : "",
        status: "open",
      };
      const row = await withAdminAuth(() =>
        pb.collection("availability_slots").create(payload),
      );
      created.push({ id: row.id, slotId: row.slot_id });
    }
    return res.status(201).json({ ownerId, createdCount: created.length, created });
  } catch (error) {
    const details = String(error);
    if (details.includes("slot_id")) {
      return res.status(409).json({ error: "One or more slotId values already exist" });
    }
    if (details.includes("404")) {
      return res.status(404).json({ error: "Owner not found" });
    }
    return res.status(500).json({ error: "Failed to create slots", details });
  }
});

app.get("/api/v1/meetings", async (req, res) => {
  try {
    const weekStart = normalizeDateOnly(req.query.weekStart);
    if (!weekStart) {
      return res
        .status(400)
        .json({ error: "weekStart query param is required (ISO date)" });
    }
    const ownerId = String(req.query.ownerId || "p1");
    const participantName = String(req.query.participantName || "").trim();
    const participantUserId = String(req.query.participantUserId || "").trim();
    const escapedOwner = ownerId.replace(/"/g, '\\"');
    const ownerMeetingRows = await withAdminAuth(() =>
      pb.collection("recurring_meetings").getFullList({
        filter: `owner_external_id="${escapedOwner}"`,
      }),
    );
    const owners = await withAdminAuth(() =>
      pb.collection("schedule_owners").getFullList(),
    );
    const ownerNameByExternalId = new Map(
      owners.map((o) => [o.external_id, o.name]),
    );
    const appUserRows = await withAdminAuth(() => pb.collection("app_users").getFullList());
    const { byId: disciplineByUserId, byName: disciplineByDisplayName } =
      buildUserDisciplineMaps(appUserRows);
    const weekStartIso = weekStart.toISOString();
    const weekEndIso = new Date(weekStart.getTime() + DAY_MS * 7).toISOString();
    const ownerBookingRows = await withAdminAuth(() =>
      pb.collection("bookings").getFullList({
        filter:
          `owner_external_id="${escapedOwner}"` +
          ` && start_time >= "${weekStartIso}"` +
          ` && start_time < "${weekEndIso}"` +
          ` && status = "confirmed"`,
      }),
    );
    const statusRows = await withAdminAuth(() =>
      pb.collection("meeting_status_events").getFullList({
        filter:
          `owner_external_id="${escapedOwner}"` +
          ` && meeting_start_time >= "${weekStartIso}"` +
          ` && meeting_start_time < "${weekEndIso}"`,
      }),
    );
    const sessionRows = await withAdminAuth(() =>
      pb.collection("sessions").getFullList({
        filter: `start_time >= "${weekStartIso}" && start_time < "${weekEndIso}"`,
      }),
    );
    const statusByKey = new Map(
      statusRows.map((r) => [
        makeMeetingEventKey(r.meeting_id, r.meeting_start_time),
        r.status,
      ]),
    );
    const sessionByLookupKey = new Map();
    for (const row of sessionRows) {
      const key = makeSessionLookupKey({
        ownerExternalId: row.owner_external_id,
        studentId: row.student_id,
        participantName: row.participant_name,
        startTime: row.start_time,
      });
      sessionByLookupKey.set(key, row);
    }
    const monday = mondayFromWeekStart(weekStart);
    const meetings = ownerMeetingRows.map((row) => {
      const start = new Date(
        Date.UTC(
          monday.getUTCFullYear(),
          monday.getUTCMonth(),
          monday.getUTCDate() + Number(row.days_after_monday),
          Number(row.start_hour),
          Number(row.start_minute),
          0,
          0,
        ),
      );
      const key = makeMeetingEventKey(row.meeting_id, start.toISOString());
      const matchedSession = sessionByLookupKey.get(
        makeSessionLookupKey({
          ownerExternalId: ownerId,
          studentId: row.student_id,
          participantName: row.participant_name,
          startTime: start.toISOString(),
        }),
      );
      return {
        id: row.meeting_id,
        participantName: row.participant_name,
        studentId: row.student_id || null,
        ownerId,
        ownerName: ownerNameByExternalId.get(ownerId) || null,
        startTime: start.toISOString(),
        durationMinutes: Number(row.duration_minutes),
        discipline: resolveStudentDiscipline({
          disciplineByUserId,
          disciplineByDisplayName,
          studentId: row.student_id,
          participantName: row.participant_name,
          fallbackDiscipline: row.discipline,
        }),
        topic: row.topic || null,
        location: row.location || null,
        minutes: matchedSession?.minutes || null,
        deliberations: matchedSession?.deliberations || null,
        sharedDocuments: parseSharedDocuments(matchedSession?.shared_documents),
        meetingStatus: statusByKey.get(key) || matchedSession?.meeting_status || null,
      };
    });
    const ownerBookedMeetings = ownerBookingRows.map((row) => {
      const matchedSession = sessionByLookupKey.get(
        makeSessionLookupKey({
          ownerExternalId: row.owner_external_id,
          studentId: row.participant_user_id,
          participantName: row.participant_name,
          startTime: row.start_time,
        }),
      );
      return {
        id: `booking-${row.id}`,
        participantName: row.participant_name || "Student",
        studentId: row.participant_user_id || null,
        ownerId: row.owner_external_id || null,
        ownerName: ownerNameByExternalId.get(row.owner_external_id) || null,
        startTime: new Date(row.start_time).toISOString(),
        durationMinutes: Number(row.duration_minutes),
        discipline: resolveStudentDiscipline({
          disciplineByUserId,
          disciplineByDisplayName,
          studentId: row.participant_user_id,
          participantName: row.participant_name,
          fallbackDiscipline: "Booked meeting",
        }),
        topic: row.title || null,
        location: row.location || null,
        minutes: matchedSession?.minutes || null,
        deliberations: matchedSession?.deliberations || null,
        sharedDocuments:
          parseSharedDocuments(matchedSession?.shared_documents).length > 0
            ? parseSharedDocuments(matchedSession?.shared_documents)
            : parseSharedDocuments(row.shared_documents),
        meetingStatus: matchedSession?.meeting_status || null,
      };
    });
    meetings.push(...ownerBookedMeetings);

    if (participantName || participantUserId) {
      const escapedParticipant = participantName.replace(/"/g, '\\"');
      const escapedParticipantUserId = participantUserId.replace(/"/g, '\\"');
      const participantClause =
        participantUserId
          ? `participant_user_id="${escapedParticipantUserId}"`
          : `participant_name="${escapedParticipant}"`;
      const bookingRows = await withAdminAuth(() =>
        pb.collection("bookings").getFullList({
          filter:
            participantClause +
            ` && start_time >= "${weekStartIso}"` +
            ` && start_time < "${weekEndIso}"` +
            ` && status = "confirmed"`,
        }),
      );
      const attendeeMeetings = bookingRows.map((row) => {
        const matchedSession = sessionByLookupKey.get(
          makeSessionLookupKey({
            ownerExternalId: row.owner_external_id,
            studentId: row.participant_user_id,
            participantName: row.participant_name,
            startTime: row.start_time,
          }),
        );
        return {
          id: `booking-${row.id}`,
          participantName: row.participant_name || participantName || "Student",
          studentId: row.participant_user_id || null,
          ownerId: row.owner_external_id || null,
          ownerName: ownerNameByExternalId.get(row.owner_external_id) || null,
          startTime: new Date(row.start_time).toISOString(),
          durationMinutes: Number(row.duration_minutes),
          discipline: resolveStudentDiscipline({
            disciplineByUserId,
            disciplineByDisplayName,
            studentId: row.participant_user_id,
            participantName: row.participant_name,
            fallbackDiscipline:
              ownerNameByExternalId.get(row.owner_external_id) ||
              row.owner_external_id ||
              "Booked meeting",
          }),
          topic: row.title || null,
          location: row.location || null,
          minutes: matchedSession?.minutes || null,
          deliberations: matchedSession?.deliberations || null,
          sharedDocuments:
            parseSharedDocuments(matchedSession?.shared_documents).length > 0
              ? parseSharedDocuments(matchedSession?.shared_documents)
              : parseSharedDocuments(row.shared_documents),
          meetingStatus: matchedSession?.meeting_status || null,
        };
      });
      meetings.push(...attendeeMeetings);
    }
    meetings.sort((a, b) => a.startTime.localeCompare(b.startTime));
    return res.status(200).json({
      weekStart: weekStart.toISOString().slice(0, 10),
      ownerId,
      meetings,
    });
  } catch (error) {
    return res.status(500).json({
      error: "Failed to fetch recurring meetings",
      details: String(error),
    });
  }
});

app.get("/api/v1/sessions/prior", async (req, res) => {
  try {
    const studentId = String(req.query.studentId || "").trim();
    const participantName = String(req.query.participantName || "").trim();
    const ownerId = String(req.query.ownerId || "").trim();
    if (!studentId && !participantName) {
      return res
        .status(400)
        .json({ error: "Provide studentId or participantName" });
    }
    let filter = "";
    if (studentId) {
      filter = `student_id="${studentId.replace(/"/g, '\\"')}"`;
    } else {
      filter = `participant_name="${participantName.replace(/"/g, '\\"')}"`;
    }
    if (ownerId) {
      filter += ` && owner_external_id="${ownerId.replace(/"/g, '\\"')}"`;
    }
    const rows = await withAdminAuth(() =>
      pb.collection("sessions").getFullList({
        filter,
      }),
    );
    const appUserRows = await withAdminAuth(() => pb.collection("app_users").getFullList());
    const { byId: disciplineByUserId, byName: disciplineByDisplayName } =
      buildUserDisciplineMaps(appUserRows);
    const eventRows = await withAdminAuth(() =>
      pb.collection("meeting_status_events").getFullList({
        filter:
          (studentId
            ? `student_id="${studentId.replace(/"/g, '\\"')}"`
            : `participant_name="${participantName.replace(/"/g, '\\"')}"`) +
          (ownerId
            ? ` && owner_external_id="${ownerId.replace(/"/g, '\\"')}"`
            : "") +
          ` && meeting_start_time < "${new Date().toISOString()}"`,
      }),
    );
    const sessions = rows.map((row) => ({
      id: row.session_id,
      participantName: row.participant_name,
      studentId: row.student_id || null,
      ownerId: row.owner_external_id || null,
      startTime: new Date(row.start_time).toISOString(),
      durationMinutes: Number(row.duration_minutes),
      discipline: resolveStudentDiscipline({
        disciplineByUserId,
        disciplineByDisplayName,
        studentId: row.student_id,
        participantName: row.participant_name,
        fallbackDiscipline: row.discipline,
      }),
      topic: row.topic || null,
      location: row.location || null,
      minutes: row.minutes || null,
      deliberations: row.deliberations || null,
      sharedDocuments: parseSharedDocuments(row.shared_documents),
      meetingStatus: row.meeting_status || null,
    }));
    const eventSessions = eventRows.map((row) => ({
      id: `status-${row.id}`,
      participantName: row.participant_name || participantName || "Student",
      studentId: row.student_id || null,
      ownerId: row.owner_external_id || ownerId || null,
      startTime: new Date(row.meeting_start_time).toISOString(),
      durationMinutes: 15,
      discipline: null,
      topic: null,
      location: null,
      minutes: null,
      deliberations: null,
      sharedDocuments: [],
      meetingStatus: row.status || null,
    }));
    sessions.push(...eventSessions);
    sessions.sort((a, b) => b.startTime.localeCompare(a.startTime));
    return res.status(200).json({ sessions });
  } catch (error) {
    return res
      .status(500)
      .json({ error: "Failed to fetch prior sessions", details: String(error) });
  }
});

app.post("/api/v1/meetings/status", async (req, res) => {
  try {
    const {
      ownerId,
      meetingId,
      startTime,
      status,
      studentId,
      participantName,
      note,
    } = req.body ?? {};

    if (!ownerId || !meetingId || !startTime || !status) {
      return res.status(400).json({
        error: "Missing required fields: ownerId, meetingId, startTime, status",
      });
    }

    const rawStatus = String(status).trim().toLowerCase();
    const normalizedStatus =
      rawStatus === "on time" || rawStatus === "ontime" ? "on_time" : rawStatus;
    const allowed = new Set(["on_time", "happened", "late", "postponed", "cancelled", "missed"]);
    if (!allowed.has(normalizedStatus)) {
      return res.status(400).json({
        error: "Invalid status. Allowed: on_time, late, postponed, cancelled, missed",
      });
    }

    const start = new Date(startTime);
    if (Number.isNaN(start.getTime())) {
      return res.status(400).json({ error: "Invalid startTime" });
    }

    const owner = await withAdminAuth(() => getOwnerByExternalId(String(ownerId)));
    const eventKey = makeMeetingEventKey(String(meetingId), start.toISOString());

    let existing = null;
    try {
      existing = await withAdminAuth(() =>
        pb
          .collection("meeting_status_events")
          .getFirstListItem(`event_key="${eventKey.replace(/"/g, '\\"')}"`),
      );
    } catch (_) {
      existing = null;
    }

    const payload = {
      event_key: eventKey,
      owner_external_id: owner.external_id,
      meeting_id: String(meetingId),
      meeting_start_time: start.toISOString(),
      student_id: studentId ? String(studentId).trim() : "",
      participant_name: participantName ? String(participantName).trim() : "",
      status: normalizedStatus,
      note: note ? String(note).trim() : "",
    };

    const saved = existing
      ? await withAdminAuth(() =>
          pb.collection("meeting_status_events").update(existing.id, payload),
        )
      : await withAdminAuth(() =>
          pb.collection("meeting_status_events").create(payload),
        );

    return res.status(existing ? 200 : 201).json({
      statusEvent: {
        id: saved.id,
        meetingId: saved.meeting_id,
        startTime: saved.meeting_start_time,
        status: saved.status,
      },
    });
  } catch (error) {
    return res
      .status(500)
      .json({ error: "Failed to update meeting status", details: String(error) });
  }
});

app.post("/api/v1/meetings/minutes", async (req, res) => {
  try {
    const {
      meetingId,
      startTime,
      participantName,
      studentId,
      ownerId,
      durationMinutes,
      discipline,
      topic,
      location,
      minutes,
      deliberations,
      sharedDocuments,
      meetingStatus,
    } = req.body ?? {};

    if (!meetingId || !startTime) {
      return res.status(400).json({
        error: "Missing required fields: meetingId, startTime",
      });
    }

    const start = new Date(startTime);
    if (Number.isNaN(start.getTime())) {
      return res.status(400).json({ error: "Invalid startTime" });
    }

    const normalizedParticipantName = String(participantName || "").trim();
    const normalizedStudentId = String(studentId || "").trim();
    if (!normalizedParticipantName && !normalizedStudentId) {
      return res.status(400).json({
        error: "participantName or studentId is required",
      });
    }

    const normalizedDuration = Number(durationMinutes);
    const safeDuration =
      Number.isFinite(normalizedDuration) && normalizedDuration >= 5 && normalizedDuration <= 480
        ? Math.trunc(normalizedDuration)
        : 30;
    const sessionId = makeMeetingEventKey(String(meetingId), start.toISOString());
    const escapedSessionId = sessionId.replace(/"/g, '\\"');

    let existing = null;
    try {
      existing = await withAdminAuth(() =>
        pb.collection("sessions").getFirstListItem(`session_id="${escapedSessionId}"`),
      );
    } catch (_) {
      existing = null;
    }

    const payload = {
      session_id: sessionId,
      owner_external_id:
        String(ownerId || "").trim() || String(existing?.owner_external_id || "").trim(),
      participant_name:
        normalizedParticipantName || String(existing?.participant_name || "Student"),
      student_id: normalizedStudentId || String(existing?.student_id || ""),
      start_time: start.toISOString(),
      duration_minutes: safeDuration,
      discipline:
        String(discipline || "").trim() || String(existing?.discipline || "").trim(),
      topic: String(topic || "").trim() || String(existing?.topic || "").trim(),
      location: String(location || "").trim() || String(existing?.location || "").trim(),
      minutes: String(minutes || "").trim(),
      deliberations: String(deliberations || "").trim(),
      shared_documents:
        parseSharedDocuments(sharedDocuments).length > 0
          ? stringifySharedDocuments(sharedDocuments)
          : String(existing?.shared_documents || "[]"),
      meeting_status:
        String(meetingStatus || "").trim() || String(existing?.meeting_status || "").trim(),
    };

    const saved = existing
      ? await withAdminAuth(() => pb.collection("sessions").update(existing.id, payload))
      : await withAdminAuth(() => pb.collection("sessions").create(payload));

    return res.status(existing ? 200 : 201).json({
      session: {
        id: saved.id,
        sessionId: saved.session_id,
        startTime: saved.start_time,
        participantName: saved.participant_name,
        studentId: saved.student_id || null,
        ownerId: saved.owner_external_id || null,
        minutes: saved.minutes || null,
        deliberations: saved.deliberations || null,
        sharedDocuments: parseSharedDocuments(saved.shared_documents),
        meetingStatus: saved.meeting_status || null,
      },
    });
  } catch (error) {
    return res
      .status(500)
      .json({ error: "Failed to save meeting minutes", details: String(error) });
  }
});

app.get("/api/v1/proxy", async (req, res) => {
  const targetUrl = req.query.url;
  if (!targetUrl) {
    return res.status(400).json({ error: "Missing url parameter" });
  }
  try {
    const response = await fetch(targetUrl, {
      headers: {
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "User-Agent": "SyncUp-Backend-Proxy/1.0",
      },
    });
    if (!response.ok) {
      return res.status(response.status).send(`Proxy error: ${response.statusText}`);
    }
    const contentType = response.headers.get("content-type");
    if (contentType) res.setHeader("Content-Type", contentType);
    const buffer = Buffer.from(await response.arrayBuffer());
    return res.send(buffer);
  } catch (err) {
    return res.status(500).json({ error: "Proxy request failed", details: String(err) });
  }
});

app.use((_req, res) => {
  res.status(404).json({ error: "Not found" });
});

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`SyncUp API listening on http://localhost:${PORT}`);
});

r