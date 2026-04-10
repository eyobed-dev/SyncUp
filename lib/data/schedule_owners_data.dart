import '../models/schedule_owner.dart';
import 'backend_seed.dart';

/// Professors / instructors for Find Schedule — from [backend_seed.json].
List<ScheduleOwner> getScheduleOwners() {
  return BackendSeed.instance.scheduleOwners;
}
