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

import '../models/availability_slot.dart';
import 'live_backend_cache.dart';

/// Returns available slots for a schedule owner in the given week from backend cache.
List<AvailabilitySlot> getAvailabilityForOwner(
  String ownerId,
  DateTime weekStart,
) {
  return LiveBackendCache.instance.availabilityFor(ownerId, weekStart) ??
      const [];
}

Future<void> syncAvailabilityForOwner(
  String ownerId,
  DateTime weekStart,
) async {
  await LiveBackendCache.instance.syncAvailability(ownerId, weekStart);
}
