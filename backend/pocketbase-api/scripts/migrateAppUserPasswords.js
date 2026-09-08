/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Database schema initialization and seed script for the PocketBase backend.
 */

import dotenv from "dotenv";
import crypto from "node:crypto";
import { withAdminAuth, pb } from "../src/pocketbase.js";

dotenv.config();

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

async function main() {
  let total = 0;
  let migrated = 0;
  let skipped = 0;

  await withAdminAuth(async () => {
    const users = await pb.collection("app_users").getFullList();
    total = users.length;
    for (const user of users) {
      const current = String(user.password || "");
      if (!current || isScryptHash(current)) {
        skipped += 1;
        continue;
      }
      const nextHashedPassword = await hashPassword(current);
      await pb.collection("app_users").update(user.id, {
        password: nextHashedPassword,
      });
      migrated += 1;
    }
  });

  // eslint-disable-next-line no-console
  console.log(
    `app_users password migration done. Total: ${total}, migrated: ${migrated}, skipped: ${skipped}`,
  );
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
