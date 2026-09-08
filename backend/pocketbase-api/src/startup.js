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

import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { authAsAdmin, pb } from "./pocketbase.js";

const execFileAsync = promisify(execFile);
const MAX_WAIT_ATTEMPTS = 20;
const WAIT_MS = 1000;

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function waitForPocketBase() {
  for (let i = 0; i < MAX_WAIT_ATTEMPTS; i += 1) {
    try {
      await authAsAdmin();
      return;
    } catch (_) {
      await sleep(WAIT_MS);
    }
  }
  throw new Error("PocketBase is not reachable/authenticated after startup wait.");
}

async function collectionExists(name) {
  try {
    await pb.collections.getOne(name);
    return true;
  } catch (_) {
    return false;
  }
}

async function ownersCount() {
  try {
    const page = await pb.collection("schedule_owners").getList(1, 1);
    return Number(page.totalItems || 0);
  } catch (_) {
    return 0;
  }
}

async function runNodeScript(scriptPath) {
  await execFileAsync(process.execPath, [scriptPath], {
    cwd: process.cwd(),
    env: process.env,
  });
}

async function ensureBackendData() {
  await waitForPocketBase();
  // Always run bootstrap to keep collection schemas in sync with code.
  await runNodeScript("scripts/bootstrapCollections.js");

  const hasOwnersCollection = await collectionExists("schedule_owners");
  if (!hasOwnersCollection) {
    // eslint-disable-next-line no-console
    console.log("Missing PocketBase collections. Running seed...");
    await runNodeScript("scripts/seedFromBackendSeed.js");
    return;
  }

  const count = await ownersCount();
  if (count === 0) {
    // eslint-disable-next-line no-console
    console.log("Owners collection is empty. Running seed...");
    await runNodeScript("scripts/seedFromBackendSeed.js");
  }
}

async function main() {
  await ensureBackendData();
  await import("./server.js");
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error("Startup initialization failed:", error);
  process.exit(1);
});
