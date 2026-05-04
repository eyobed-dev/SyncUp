import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_user_session.dart';
import '../models/availability_slot.dart';
import '../models/meeting.dart';
import '../models/schedule_owner.dart';

class SyncUpApiClient {
  SyncUpApiClient({String? baseUrl}) : _baseUrl = _resolveBaseUrl(baseUrl);

  final String _baseUrl;

  static String _resolveBaseUrl(String? explicitBaseUrl) {
    final explicit = (explicitBaseUrl ?? '').trim();
    if (explicit.isNotEmpty) return explicit;

    final fromEnv =
        const String.fromEnvironment('SYNCUP_API_URL', defaultValue: '').trim();
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kDebugMode) {
      return 'http://127.0.0.1:8080';
    }

    // For Flutter web deployments, default to the current host/origin.
    if (kIsWeb) return Uri.base.origin;
    return 'http://161.97.70.30:18080';
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(_baseUrl);
    return base.replace(
      path: '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query,
    );
  }

  Future<AppUserSession> login({
    required String username,
    required String password,
  }) async {
    final resp = await http.post(
      _uri('/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username.trim(), 'password': password}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Login failed (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final roleRaw = (user['role'] as String? ?? '').trim().toLowerCase();
    final role = roleRaw == 'owner' ? AppUserRole.owner : AppUserRole.attendee;
    return AppUserSession(
      userId: user['id'] as String,
      username: user['username'] as String,
      role: role,
      displayName: user['displayName'] as String,
      ownerId: user['ownerId'] as String?,
      discipline: user['discipline'] as String?,
    );
  }

  Future<List<ScheduleOwner>> fetchOwners() async {
    final resp = await http.get(_uri('/api/v1/owners'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch owners (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final owners = (data['owners'] as List<dynamic>? ?? const []);
    return owners.map((o) {
      final m = o as Map<String, dynamic>;
      return ScheduleOwner(
        id: m['id'] as String,
        name: m['name'] as String,
        role: m['role'] as String?,
        department: m['department'] as String?,
        email: m['email'] as String?,
      );
    }).toList();
  }

  Future<List<AvailabilitySlot>> fetchAvailability({
    required String ownerId,
    required DateTime weekStart,
  }) async {
    final dateOnly =
        DateTime.utc(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        ).toIso8601String().split('T').first;
    final resp = await http.get(
      _uri('/api/v1/owners/$ownerId/availability', {'weekStart': dateOnly}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch availability (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final slots = (data['slots'] as List<dynamic>? ?? const []);
    return slots.map((s) {
      final m = s as Map<String, dynamic>;
      return AvailabilitySlot(
        id: m['id'] as String,
        startTime: DateTime.parse(m['startTime'] as String).toLocal(),
        durationMinutes: (m['durationMinutes'] as num).toInt(),
        title: m['title'] as String,
        location: m['location'] as String?,
        meetingLink: m['meetingLink'] as String?,
      );
    }).toList();
  }

  Future<List<Meeting>> fetchMeetings({
    required DateTime weekStart,
    String ownerId = 'p1',
    String? participantName,
    String? participantUserId,
  }) async {
    final dateOnly =
        DateTime.utc(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        ).toIso8601String().split('T').first;
    final query = <String, String>{'weekStart': dateOnly, 'ownerId': ownerId};
    final normalizedParticipant = participantName?.trim() ?? '';
    if (normalizedParticipant.isNotEmpty) {
      query['participantName'] = normalizedParticipant;
    }
    final normalizedParticipantUserId = participantUserId?.trim() ?? '';
    if (normalizedParticipantUserId.isNotEmpty) {
      query['participantUserId'] = normalizedParticipantUserId;
    }
    final resp = await http.get(_uri('/api/v1/meetings', query));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch meetings (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final meetings = (data['meetings'] as List<dynamic>? ?? const []);
    return meetings.map((e) {
      final m = e as Map<String, dynamic>;
      return Meeting(
        id: m['id'] as String,
        participantName: m['participantName'] as String,
        studentId: m['studentId'] as String?,
        startTime: DateTime.parse(m['startTime'] as String).toLocal(),
        durationMinutes: (m['durationMinutes'] as num).toInt(),
        discipline: m['discipline'] as String?,
        topic: m['topic'] as String?,
        location: m['location'] as String?,
        minutes: m['minutes'] as String?,
        deliberations: m['deliberations'] as String?,
        meetingStatus: m['meetingStatus'] as String?,
      );
    }).toList();
  }

  Future<List<Meeting>> fetchPriorSessions({
    String? studentId,
    String? participantName,
  }) async {
    final query = <String, String>{};
    if (studentId != null && studentId.trim().isNotEmpty) {
      query['studentId'] = studentId.trim();
    }
    if (participantName != null && participantName.trim().isNotEmpty) {
      query['participantName'] = participantName.trim();
    }
    final resp = await http.get(_uri('/api/v1/sessions/prior', query));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch prior sessions (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final sessions = (data['sessions'] as List<dynamic>? ?? const []);
    return sessions.map((e) {
      final m = e as Map<String, dynamic>;
      return Meeting(
        id: m['id'] as String,
        participantName: m['participantName'] as String,
        studentId: m['studentId'] as String?,
        startTime: DateTime.parse(m['startTime'] as String).toLocal(),
        durationMinutes: (m['durationMinutes'] as num).toInt(),
        discipline: m['discipline'] as String?,
        topic: m['topic'] as String?,
        location: m['location'] as String?,
        minutes: m['minutes'] as String?,
        deliberations: m['deliberations'] as String?,
        meetingStatus: m['meetingStatus'] as String?,
      );
    }).toList();
  }

  Future<void> bookSlot({
    required String ownerId,
    required String slotId,
    required DateTime weekStart,
    required String participantName,
    String? participantUserId,
    String? participantEmail,
    String? note,
  }) async {
    final dateOnly =
        DateTime.utc(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        ).toIso8601String().split('T').first;
    final payload = {
      'ownerId': ownerId,
      'slotId': slotId,
      'weekStart': dateOnly,
      'participantName': participantName,
      'participantUserId': participantUserId ?? '',
      'participantEmail': participantEmail ?? '',
      'note': note ?? '',
    };
    final resp = await http.post(
      _uri('/api/v1/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode != 201) {
      throw Exception('Failed to book slot (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<void> cancelBooking({
    required String bookingId,
    String? participantUserId,
    String? participantName,
    String? cancelReason,
  }) async {
    final payload = {
      'participantUserId': participantUserId ?? '',
      'participantName': participantName ?? '',
      'cancelReason': cancelReason ?? '',
    };
    final resp = await http.post(
      _uri('/api/v1/bookings/$bookingId/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to cancel booking (${resp.statusCode}): ${resp.body}',
      );
    }
  }

  Future<void> createAvailabilitySlots({
    required String ownerId,
    required List<AvailabilitySlot> slots,
  }) async {
    final payload = {
      'slots':
          slots
              .map(
                (s) => {
                  'slotId': s.id,
                  'startTime': s.startTime.toUtc().toIso8601String(),
                  'durationMinutes': s.durationMinutes,
                  'title': s.title,
                  'location': s.location ?? '',
                  'meetingLink': s.meetingLink ?? '',
                },
              )
              .toList(),
    };
    final resp = await http.post(
      _uri('/api/v1/owners/$ownerId/availability/slots/bulk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode != 201) {
      throw Exception(
        'Failed to create availability slots (${resp.statusCode}): ${resp.body}',
      );
    }
  }

  Future<void> updateMeetingStatus({
    required String ownerId,
    required String meetingId,
    required DateTime startTime,
    required String status,
    String? studentId,
    String? participantName,
    String? note,
  }) async {
    final payload = {
      'ownerId': ownerId,
      'meetingId': meetingId,
      'startTime': startTime.toUtc().toIso8601String(),
      'status': status,
      'studentId': studentId ?? '',
      'participantName': participantName ?? '',
      'note': note ?? '',
    };
    final resp = await http.post(
      _uri('/api/v1/meetings/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Failed to update meeting status (${resp.statusCode}): ${resp.body}',
      );
    }
  }
}
