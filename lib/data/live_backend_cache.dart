import '../models/availability_slot.dart';
import '../models/meeting.dart';
import '../models/schedule_owner.dart';
import '../services/syncup_api_client.dart';
import '../utils/week_calendar.dart';

class LiveBackendCache {
  LiveBackendCache._();

  static final LiveBackendCache instance = LiveBackendCache._();

  static const bool enabled = bool.fromEnvironment(
    'SYNCUP_USE_BACKEND',
    defaultValue: true,
  );

  final SyncUpApiClient _api = SyncUpApiClient();
  List<ScheduleOwner> _owners = const [];
  final Map<String, List<AvailabilitySlot>> _availabilityByWeekOwner = {};
  final Map<String, List<Meeting>> _meetingsByWeek = {};
  final Map<String, List<Meeting>> _priorSessionsByBookingKey = {};

  List<ScheduleOwner> get owners => _owners;

  static String _weekKey(DateTime weekStart) {
    final sun = startOfWeekSunday(
      DateTime(weekStart.year, weekStart.month, weekStart.day),
    );
    return '${sun.year}-${sun.month}-${sun.day}';
  }

  static String _availabilityKey(String ownerId, DateTime weekStart) =>
      '${_weekKey(weekStart)}|$ownerId';

  List<AvailabilitySlot>? availabilityFor(String ownerId, DateTime weekStart) {
    return _availabilityByWeekOwner[_availabilityKey(ownerId, weekStart)];
  }

  List<Meeting>? meetingsForWeek(DateTime weekStart) {
    return _meetingsByWeek[_weekKey(weekStart)];
  }

  List<Meeting>? priorSessionsForBooking(Meeting booking) {
    final key = _sessionKey(booking);
    return _priorSessionsByBookingKey[key];
  }

  static String _sessionKey(Meeting booking) {
    final sid = booking.studentId?.trim();
    final owner = booking.ownerId?.trim() ?? '';
    if (sid != null && sid.isNotEmpty) return 'owner:$owner|sid:$sid';
    return 'owner:$owner|name:${booking.participantName.trim().toLowerCase()}';
  }

  Future<void> syncOwners() async {
    if (!enabled) return;
    _owners = await _api.fetchOwners();
  }

  Future<void> syncAvailability(String ownerId, DateTime weekStart) async {
    if (!enabled) return;
    Future<List<AvailabilitySlot>> loadOnce() {
      return _api.fetchAvailability(
        ownerId: ownerId,
        weekStart: weekStart,
      );
    }

    try {
      final list = await loadOnce();
      _availabilityByWeekOwner[_availabilityKey(ownerId, weekStart)] = list;
      return;
    } catch (_) {
      // Retry once for transient backend failures.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final list = await loadOnce();
      _availabilityByWeekOwner[_availabilityKey(ownerId, weekStart)] = list;
    }
  }

  Future<void> syncMeetings(
    DateTime weekStart, {
    String ownerId = 'p1',
    String? participantName,
    String? participantUserId,
  }) async {
    if (!enabled) return;
    Future<List<Meeting>> loadOnce() {
      return _api.fetchMeetings(
        weekStart: weekStart,
        ownerId: ownerId,
        participantName: participantName,
        participantUserId: participantUserId,
      );
    }

    try {
      final list = await loadOnce();
      _meetingsByWeek[_weekKey(weekStart)] = list;
      return;
    } catch (_) {
      // Transient backend hiccup guard: retry once shortly after failure.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final list = await loadOnce();
      _meetingsByWeek[_weekKey(weekStart)] = list;
    }
  }

  Future<void> syncPriorSessions(Meeting booking) async {
    if (!enabled) return;
    final key = _sessionKey(booking);
    final list = await _api.fetchPriorSessions(
      studentId: booking.studentId,
      participantName: booking.participantName,
      ownerId: booking.ownerId,
    );
    _priorSessionsByBookingKey[key] = list;
  }

  Future<void> bookSlot({
    required String ownerId,
    required String slotId,
    required DateTime weekStart,
    required String participantName,
    String? participantUserId,
    String? participantEmail,
    String? note,
    List<SharedDocument> sharedDocuments = const [],
  }) async {
    if (!enabled) return;
    await _api.bookSlot(
      ownerId: ownerId,
      slotId: slotId,
      weekStart: weekStart,
      participantName: participantName,
      participantUserId: participantUserId,
      participantEmail: participantEmail,
      note: note,
      sharedDocuments: sharedDocuments,
    );
  }

  Future<void> cancelBooking({
    required String bookingId,
    String? participantUserId,
    String? participantName,
    String? cancelReason,
  }) async {
    if (!enabled) return;
    await _api.cancelBooking(
      bookingId: bookingId,
      participantUserId: participantUserId,
      participantName: participantName,
      cancelReason: cancelReason,
    );
  }

  Future<void> createAvailabilitySlots({
    required String ownerId,
    required List<AvailabilitySlot> slots,
  }) async {
    if (!enabled) return;
    if (slots.isEmpty) return;
    await _api.createAvailabilitySlots(ownerId: ownerId, slots: slots);
  }

  /// Optimistically upsert availability slots into in-memory cache.
  /// Keeps UI stable while backend sync is in-flight or temporarily failing.
  void upsertAvailabilitySlotsLocal({
    required String ownerId,
    required List<AvailabilitySlot> slots,
  }) {
    if (slots.isEmpty) return;
    for (final slot in slots) {
      final key = _availabilityKey(ownerId, slot.startTime);
      final list = List<AvailabilitySlot>.from(_availabilityByWeekOwner[key] ?? const []);
      final idx = list.indexWhere(
        (s) => s.id == slot.id || (s.startTime == slot.startTime && s.durationMinutes == slot.durationMinutes),
      );
      if (idx >= 0) {
        list[idx] = slot;
      } else {
        list.add(slot);
      }
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      _availabilityByWeekOwner[key] = list;
    }
  }

  Future<void> updateMeetingStatus({
    required String ownerId,
    required Meeting meeting,
    required String status,
    String? note,
  }) async {
    if (!enabled) return;
    await _api.updateMeetingStatus(
      ownerId: ownerId,
      meetingId: meeting.id,
      startTime: meeting.startTime,
      status: status,
      studentId: meeting.studentId,
      participantName: meeting.participantName,
      note: note,
    );
    final week = _weekKey(meeting.startTime);
    final list = _meetingsByWeek[week];
    if (list == null) return;
    _meetingsByWeek[week] =
        list
            .map(
              (m) =>
                  m.id == meeting.id && m.startTime == meeting.startTime
                      ? m.copyWith(meetingStatus: status)
                      : m,
            )
            .toList();
  }

  Future<void> saveMeetingMinutes({
    required Meeting meeting,
    required String minutes,
    required String deliberations,
    List<SharedDocument>? sharedDocuments,
  }) async {
    if (!enabled) return;
    final docsToSave = sharedDocuments ?? meeting.sharedDocuments;
    await _api.saveMeetingMinutes(
      meeting: meeting,
      minutes: minutes,
      deliberations: deliberations,
      sharedDocuments: docsToSave,
    );

    final week = _weekKey(meeting.startTime);
    final list = _meetingsByWeek[week];
    if (list != null) {
      _meetingsByWeek[week] =
          list
              .map(
                (m) =>
                    m.id == meeting.id && m.startTime == meeting.startTime
                        ? m.copyWith(
                            minutes: minutes,
                            deliberations: deliberations,
                            sharedDocuments: docsToSave,
                          )
                        : m,
              )
              .toList();
    }

    final priorKey = _sessionKey(meeting);
    final priorList = List<Meeting>.from(_priorSessionsByBookingKey[priorKey] ?? const []);
    final idx = priorList.indexWhere(
      (m) => m.id == meeting.id && m.startTime == meeting.startTime,
    );
    final updatedMeeting = meeting.copyWith(
      minutes: minutes,
      deliberations: deliberations,
      sharedDocuments: docsToSave,
    );
    if (idx >= 0) {
      priorList[idx] = priorList[idx].copyWith(
        minutes: minutes,
        deliberations: deliberations,
        sharedDocuments: docsToSave,
      );
    } else {
      priorList.add(updatedMeeting);
    }
    priorList.sort((a, b) => b.startTime.compareTo(a.startTime));
    _priorSessionsByBookingKey[priorKey] = priorList;
  }
}
