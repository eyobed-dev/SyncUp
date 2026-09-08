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

import '../models/meeting.dart';

class CurrentMeetingMinutes {
  final String minutes;
  final String deliberations;
  final DateTime updatedAt;

  const CurrentMeetingMinutes({
    required this.minutes,
    required this.deliberations,
    required this.updatedAt,
  });
}

/// In-memory demo store for "this meeting" minutes.
class CurrentMeetingMinutesStore {
  static final Map<String, CurrentMeetingMinutes> _byMeetingId = {};

  static CurrentMeetingMinutes? get(Meeting m) => _byMeetingId[m.id];

  static void put(Meeting m, {required String minutes, required String deliberations}) {
    _byMeetingId[m.id] = CurrentMeetingMinutes(
      minutes: minutes,
      deliberations: deliberations,
      updatedAt: DateTime.now(),
    );
  }
}

