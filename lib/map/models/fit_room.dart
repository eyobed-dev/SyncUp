/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Defines data models and entities for fit_room.
 */

import 'package:flutter/material.dart';

class FitRoom {
  final String id;
  final String title;
  final String floorNo;
  final String roomTag;
  final String roomType; // 'lecture', 'laboratory', 'library', 'study', 'office', 'toilets', 'corridor', 'stairs', 'elevator', 'other'
  final String? onclick;
  final List<Offset> coords;
  final List<(double, double)> gpsCoords;

  late final Offset center = _calculateCenter();
  late final Rect bounds = _calculateBounds();

  FitRoom({
    required this.id,
    required this.title,
    required this.floorNo,
    this.roomTag = '',
    this.roomType = 'other',
    this.onclick,
    required this.coords,
    this.gpsCoords = const [],
  });

  factory FitRoom.fromJson(String id, Map<String, dynamic> json) {
    final rawCoords = json['coords'] as List<dynamic>? ?? [];
    final coordsList = <Offset>[];
    for (final pt in rawCoords) {
      if (pt is List<dynamic> && pt.length >= 2) {
        final x = (pt[0] as num).toDouble();
        final y = (pt[1] as num).toDouble();
        coordsList.add(Offset(x, y));
      }
    }

    final rawGps = json['gps_coords'] as List<dynamic>? ?? [];
    final gpsList = <(double, double)>[];
    for (final g in rawGps) {
      if (g is List<dynamic> && g.length >= 2) {
        final lat = (g[0] as num).toDouble();
        final lng = (g[1] as num).toDouble();
        gpsList.add((lat, lng));
      }
    }

    final title = (json['title'] as String?) ?? id;
    final rawType = json['room_type'] as String?;
    final resolvedType = rawType ?? _inferType(id, title);

    return FitRoom(
      id: id,
      title: title,
      floorNo: (json['floor_no']?.toString().replaceAll('+', '').trim()) ?? '1',
      roomTag: (json['room_tag'] as String?)?.trim() ?? '',
      roomType: resolvedType,
      onclick: json['onclick'] as String?,
      coords: coordsList,
      gpsCoords: gpsList,
    );
  }

  static String _inferType(String id, String title) {
    final lower = title.toLowerCase();
    final lowerId = id.toLowerCase();
    if (lower.contains('toilet') || lower.contains('wc') || lower.contains('toaleta')) return 'toilets';
    if (lower.contains('staircase') || lower.contains('stairs') || lower.contains('schodiště')) return 'stairs';
    if (lower.contains('elevator') || lower.contains('lift') || lower.contains('výtah')) return 'elevator';
    if (lower.contains('corridor') || lower.contains('chodba') || lower.contains('hallway') || lowerId.startsWith('door_')) return 'corridor';
    if (lower.contains('lecture') || lower.contains('posluchárna') || lower.contains('aula')) return 'lecture';
    if (lower.contains('lab') || lower.contains('laboratoř')) return 'laboratory';
    if (lower.contains('library') || lower.contains('knihovna')) return 'library';
    if (lower.contains('study') || lower.contains('studovna') || lower.contains('seminar')) return 'study';
    if (lower.contains('office') || lower.contains('kancelář')) return 'office';
    return 'other';
  }

  Offset _calculateCenter() {
    if (coords.isEmpty) return Offset.zero;
    double sumX = 0;
    double sumY = 0;
    for (final p in coords) {
      sumX += p.dx;
      sumY += p.dy;
    }
    return Offset(sumX / coords.length, sumY / coords.length);
  }

  Rect _calculateBounds() {
    if (coords.isEmpty) return Rect.zero;
    double minX = coords.first.dx;
    double maxX = coords.first.dx;
    double minY = coords.first.dy;
    double maxY = coords.first.dy;

    for (final p in coords) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool get isCorridor => roomType == 'corridor' || title.toLowerCase().contains('corridor');
  bool get isStaircase => roomType == 'stairs' || title.toLowerCase().contains('staircase') || title.toLowerCase().contains('stairs');
  bool get isElevator => roomType == 'elevator' || title.toLowerCase().contains('elevator');
  bool get isRestroom => roomType == 'toilets' || title.toLowerCase().contains('wc') || title.toLowerCase().contains('toilet');
  bool get isLecture => roomType == 'lecture';
  bool get isLaboratory => roomType == 'laboratory';
  bool get isLibrary => roomType == 'library';
  bool get isStudy => roomType == 'study';
  bool get isOffice => roomType == 'office';
  bool get isOther => roomType == 'other' || roomType == 'common' || roomType == 'cellar';

  String get displayLabel {
    if (isRestroom) return 'WC';
    if (isElevator) return 'V';
    return id;
  }

  bool get isWheelchairAccessible {
    final lower = roomTag.toLowerCase();
    if (lower.contains('not wheelchair accessible')) return false;
    if (lower.contains('wheelchair accessible')) return true;
    return false;
  }

  String get floorLabel {
    switch (floorNo) {
      case '-2':
        return 'Basement -2';
      case '-1':
        return 'Basement -1';
      case '1':
        return '1st Floor (Ground)';
      case '2':
        return '2nd Floor';
      case '3':
        return '3rd Floor';
      case '4':
        return '4th Floor';
      default:
        return 'Floor $floorNo';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'floor_no': floorNo,
      'room_tag': roomTag,
      'room_type': roomType,
      'onclick': onclick,
      'coords': coords.map((c) => [c.dx, c.dy]).toList(),
    };
  }
}
