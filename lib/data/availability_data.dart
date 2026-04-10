import '../models/availability_slot.dart';
import 'backend_seed.dart';

/// Returns available slots for a schedule owner in the given week (from [backend_seed.json]).
List<AvailabilitySlot> getAvailabilityForOwner(String ownerId, DateTime weekStart) {
  return BackendSeed.instance.availabilityForOwner(ownerId, weekStart);
}
