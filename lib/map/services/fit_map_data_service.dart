/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Provides business logic and API integrations for fit_map_data_service.
 */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fit_room.dart';
import '../models/campus_feature.dart';
import '../data/campus_features_data.dart';

class FitMapDataService {
  FitMapDataService._();
  static final FitMapDataService instance = FitMapDataService._();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  final List<FitRoom> _allRooms = [];
  final Map<String, FitRoom> _roomsById = {};
  final Map<String, List<FitRoom>> _roomsByFloor = {
    '-2': [],
    '-1': [],
    '1': [],
    '2': [],
    '3': [],
    '4': [],
  };
  final Map<String, Rect> _floorBounds = {};

  List<BuildingFootprint> get footprints => CampusFeaturesData.footprints;
  List<BuildingLetter> get buildingLetters => CampusFeaturesData.buildingLetters;
  List<StreetLabel> get streetLabels => CampusFeaturesData.streetLabels;

  List<FitRoom> get allRooms => List.unmodifiable(_allRooms);

  List<FitRoom> roomsForFloor(String floorNo) {
    return _roomsByFloor[floorNo] ?? const [];
  }

  FitRoom? getRoomById(String roomId) {
    final cleanId = roomId.trim().toUpperCase();
    return _roomsById[cleanId];
  }

  /// Attempts to find a room matching a loose string like "Room C201", "C 201", "A-112", "Office 312", etc.
  FitRoom? findRoomByLooseString(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final clean = text.trim();

    // 1. Direct match by ID
    final cleanUpper = clean.toUpperCase();
    if (_roomsById.containsKey(cleanUpper)) {
      return _roomsById[cleanUpper];
    }

    // 2. Extract potential room code via regex: e.g. "[A-Z][0-9]{3,4}" or "A-112"
    final codeRegExp = RegExp(r'\b([A-Za-z])[- ]?([0-9]{3,4}[a-zA-Z]?)\b');
    final codeMatch = codeRegExp.firstMatch(clean);
    if (codeMatch != null) {
      final candidate = '${codeMatch.group(1)}${codeMatch.group(2)}'.toUpperCase();
      if (_roomsById.containsKey(candidate)) {
        return _roomsById[candidate];
      }
    }

    // 3. Extract 3-4 digit number and find rooms ending with that number (e.g. "Office 312" -> "L312" or "A312")
    final numRegExp = RegExp(r'\b([0-9]{3,4}[a-zA-Z]?)\b');
    final numMatch = numRegExp.firstMatch(clean);
    if (numMatch != null) {
      final numStr = numMatch.group(1)!.toUpperCase();
      for (final entry in _roomsById.entries) {
        if (entry.key.endsWith(numStr)) {
          return entry.value;
        }
      }
    }

    // 4. Check if clean string contains any known room ID
    for (final entry in _roomsById.entries) {
      if (cleanUpper.contains(entry.key)) {
        return entry.value;
      }
    }

    // 5. Check if room title contains clean string (case-insensitive)
    final lower = clean.toLowerCase();
    for (final room in _allRooms) {
      if (room.title.toLowerCase().contains(lower)) {
        return room;
      }
    }

    return null;
  }

  Rect get globalBounds {
    if (_allRooms.isEmpty) {
      return const Rect.fromLTWH(0, 0, 700, 1000);
    }

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final r in _allRooms) {
      if (r.coords.isEmpty) continue;
      final b = r.bounds;
      if (b.left < minX) minX = b.left;
      if (b.right > maxX) maxX = b.right;
      if (b.top < minY) minY = b.top;
      if (b.bottom > maxY) maxY = b.bottom;
    }

    if (minX.isInfinite) {
      return const Rect.fromLTWH(0, 0, 700, 1000);
    }

    // Add padding around map bounds
    return Rect.fromLTRB(
      minX - 40,
      minY - 40,
      maxX + 40,
      maxY + 40,
    );
  }

  Rect boundsForFloor(String floorNo) {
    return globalBounds;
  }

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/maps_data_merged.json');
      final dynamic raw = jsonDecode(jsonString);

      if (raw is! List) {
        throw const FormatException('Expected JSON list in maps_data_merged.json');
      }

      _allRooms.clear();
      _roomsById.clear();
      for (final list in _roomsByFloor.values) {
        list.clear();
      }
      _floorBounds.clear();

      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          for (final entry in item.entries) {
            final roomId = entry.key.trim().toUpperCase();
            final roomData = entry.value as Map<String, dynamic>;
            final room = FitRoom.fromJson(roomId, roomData);

            _allRooms.add(room);
            _roomsById[roomId] = room;

            final floorKey = room.floorNo;
            if (_roomsByFloor.containsKey(floorKey)) {
              _roomsByFloor[floorKey]!.add(room);
            } else {
              _roomsByFloor[floorKey] = [room];
            }
          }
        }
      }

      _isLoaded = true;
    } catch (e, stack) {
      debugPrint('Error loading FIT map room data: $e\n$stack');
      rethrow;
    }
  }

  List<FitRoom> search(String query, {int limit = 10}) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return const [];

    final exactMatches = <FitRoom>[];
    final prefixMatches = <FitRoom>[];
    final titleMatches = <FitRoom>[];

    for (final room in _allRooms) {
      final idLower = room.id.toLowerCase();
      final titleLower = room.title.toLowerCase();

      if (idLower == clean) {
        exactMatches.add(room);
      } else if (idLower.startsWith(clean)) {
        prefixMatches.add(room);
      } else if (titleLower.contains(clean) || room.roomTag.toLowerCase().contains(clean)) {
        titleMatches.add(room);
      }
    }

    final combined = [...exactMatches, ...prefixMatches, ...titleMatches];
    if (combined.length > limit) {
      return combined.sublist(0, limit);
    }
    return combined;
  }
}
