import '../models/schedule_owner.dart';
import 'live_backend_cache.dart';

/// Professors / instructors for Find Schedule — from backend API cache.
List<ScheduleOwner> getScheduleOwners() {
  return LiveBackendCache.instance.owners;
}

Future<void> syncScheduleOwners() async {
  await LiveBackendCache.instance.syncOwners();
}
