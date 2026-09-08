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
import PocketBase from "pocketbase";

dotenv.config();

const requiredEnv = [
  "POCKETBASE_URL",
  "POCKETBASE_SUPERUSER_EMAIL",
  "POCKETBASE_SUPERUSER_PASSWORD",
];

for (const key of requiredEnv) {
  if (!process.env[key]) {
    throw new Error(`Missing required env var: ${key}`);
  }
}

export const pb = new PocketBase(process.env.POCKETBASE_URL);

let _adminAuthInFlight = null;

async function _authenticateAdmin() {
  pb.authStore.clear();
  await pb.collection("_superusers").authWithPassword(
    process.env.POCKETBASE_SUPERUSER_EMAIL,
    process.env.POCKETBASE_SUPERUSER_PASSWORD,
  );
}

export async function authAsAdmin({ force = false } = {}) {
  if (!force && pb.authStore.isValid) return;
  if (_adminAuthInFlight) {
    await _adminAuthInFlight;
    return;
  }
  _adminAuthInFlight = _authenticateAdmin();
  try {
    await _adminAuthInFlight;
  } finally {
    _adminAuthInFlight = null;
  }
}

export async function withAdminAuth(fn) {
  await authAsAdmin();
  try {
    return await fn();
  } catch (error) {
    const details = String(error);
    const isAuthError =
      details.includes("401") ||
      details.includes("403") ||
      details.toLowerCase().includes("unauthorized");
    if (!isAuthError) throw error;
    await authAsAdmin({ force: true });
    return fn();
  }
}

