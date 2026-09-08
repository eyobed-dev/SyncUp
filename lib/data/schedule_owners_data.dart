/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Static datasets or mock data providers.
 */

import '../models/schedule_owner.dart';
import 'live_backend_cache.dart';

/// Professors / instructors for Find Schedule — from backend API cache.
List<ScheduleOwner> getScheduleOwners() {
  return LiveBackendCache.instance.owners;
}

Future<void> syncScheduleOwners() async {
  await LiveBackendCache.instance.syncOwners();
}
