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
