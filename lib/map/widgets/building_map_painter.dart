/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Reusable UI component for the building_map_painter interface.
 */

import 'package:flutter/material.dart';
import '../models/fit_room.dart';
import '../models/map_path.dart';
import '../models/campus_feature.dart';
import '../theme/fit_map_theme.dart';

class BuildingMapPainter extends CustomPainter {
  final List<FitRoom> rooms;
  final List<BuildingFootprint> footprints;
  final List<BuildingLetter> buildingLetters;
  final List<StreetLabel> streetLabels;
  final Set<String> highlightedRoomIds;
  final String? selectedRoomId;
  final String? startRoomId;
  final String? destinationRoomId;
  final double pulseValue; // 0.0 to 1.0 for pulsing highlights
  final List<MapPath> paths;
  final List<FloorTransitionMarker> transitionMarkers;
  final bool isDarkMode;
  final double currentZoom;

  BuildingMapPainter({
    required this.rooms,
    this.footprints = const [],
    this.buildingLetters = const [],
    this.streetLabels = const [],
    this.highlightedRoomIds = const {},
    this.selectedRoomId,
    this.startRoomId,
    this.destinationRoomId,
    required this.pulseValue,
    this.paths = const [],
    this.transitionMarkers = const [],
    this.isDarkMode = false,
    this.currentZoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Campus Background Footprints & Walkways
    _drawFootprints(canvas);

    // 2. Draw Room Fills and Borders
    _drawRooms(canvas);

    // 3. Draw Street and Entrance Labels
    _drawStreetLabels(canvas);

    // 4. Draw Building Wing Letters (A, B, C, D, E...)
    _drawBuildingLetters(canvas);

    // 5. Draw Navigation Paths (Route)
    _drawPaths(canvas);

    // 6. Draw Room Labels (adaptive sizing, boundary check, and collision avoidance)
    _drawLabels(canvas);

    // 7. Draw Markers for Start ('A') and Destination ('B')
    _drawMarkers(canvas);
  }

  void _drawFootprints(Canvas canvas) {
    if (footprints.isEmpty) return;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode ? FitMapTheme.footprintDark : FitMapTheme.footprintLight;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isDarkMode ? FitMapTheme.footprintBorderDark : FitMapTheme.footprintBorderLight;

    for (final fp in footprints) {
      if (fp.points.length < 3) continue;
      final path = Path()..moveTo(fp.points.first.dx, fp.points.first.dy);
      for (int i = 1; i < fp.points.length; i++) {
        path.lineTo(fp.points[i].dx, fp.points[i].dy);
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawStreetLabels(Canvas canvas) {
    if (streetLabels.isEmpty) return;

    final textColor = isDarkMode ? FitMapTheme.streetLabelDark : FitMapTheme.streetLabelLight;

    for (final st in streetLabels) {
      final textSpan = TextSpan(
        text: st.text,
        style: TextStyle(
          color: textColor,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(st.position.dx, st.position.dy);
      if (st.angle != 0.0) {
        canvas.rotate(st.angle * 3.141592653589793 / 180.0);
      }
      textPainter.paint(canvas, Offset(0, -textPainter.height));
      canvas.restore();
    }
  }

  void _drawBuildingLetters(Canvas canvas) {
    if (buildingLetters.isEmpty) return;

    for (final bl in buildingLetters) {
      final textSpan = TextSpan(
        text: bl.letter,
        style: const TextStyle(
          color: FitMapTheme.buildingWingLetter,
          fontSize: 27.0,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          bl.position.dx - (textPainter.width / 2),
          bl.position.dy - textPainter.height,
        ),
      );
    }
  }

  void _drawRooms(Canvas canvas) {
    if (rooms.isEmpty) return;

    for (final room in rooms) {
      if (room.coords.length < 3) continue;

      final isHighlighted = highlightedRoomIds.contains(room.id);
      final isSelected = selectedRoomId == room.id;
      final isStart = startRoomId == room.id;
      final isDest = destinationRoomId == room.id;

      final path = Path()..moveTo(room.coords.first.dx, room.coords.first.dy);
      for (int i = 1; i < room.coords.length; i++) {
        path.lineTo(room.coords[i].dx, room.coords[i].dy);
      }
      path.close();

      // Room Fill: Official FIT VUT Color Code
      final fillPaint = Paint()..style = PaintingStyle.fill;
      if (isStart) {
        fillPaint.color = const Color(0xFF10B981).withValues(alpha: 0.65 + (0.25 * pulseValue));
      } else if (isDest || isSelected) {
        fillPaint.color = const Color(0xFF0D9488).withValues(alpha: 0.65 + (0.25 * pulseValue));
      } else if (isHighlighted) {
        fillPaint.color = const Color(0xFFF59E0B).withValues(alpha: 0.65 + (0.25 * pulseValue));
      } else {
        fillPaint.color = FitMapTheme.getRoomFill(room, isDarkMode: isDarkMode);
      }
      canvas.drawPath(path, fillPaint);

      // Room Border: Crisp outlines matching official map
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isSelected || isStart || isDest)
            ? (2.8 * (0.8 + 0.3 * pulseValue))
            : (isHighlighted ? 2.2 : 0.85);

      if (isStart) {
        borderPaint.color = const Color(0xFF047857);
      } else if (isDest || isSelected) {
        borderPaint.color = const Color(0xFF0F766E);
      } else if (isHighlighted) {
        borderPaint.color = const Color(0xFFB45309);
      } else {
        borderPaint.color = isDarkMode ? FitMapTheme.roomBorderDark : FitMapTheme.roomBorderLight;
      }
      canvas.drawPath(path, borderPaint);
    }
  }

  List<Offset> _convertToRightAngledPath(List<Offset> points) {
    if (points.length < 2) return points;

    final rightAngledPoints = <Offset>[points[0]];

    for (int i = 1; i < points.length; i++) {
      final prev = rightAngledPoints.last;
      final current = points[i];

      final dx = current.dx - prev.dx;
      final dy = current.dy - prev.dy;

      if (dx.abs() > 0.1 && dy.abs() > 0.1) {
        if (dx.abs() > dy.abs()) {
          rightAngledPoints.add(Offset(current.dx, prev.dy));
          rightAngledPoints.add(Offset(current.dx, current.dy));
        } else {
          rightAngledPoints.add(Offset(prev.dx, current.dy));
          rightAngledPoints.add(Offset(current.dx, current.dy));
        }
      } else {
        if (dx.abs() > 0.1 || dy.abs() > 0.1) {
          rightAngledPoints.add(current);
        }
      }
    }

    return rightAngledPoints;
  }

  void _drawPaths(Canvas canvas) {
    for (final mapPath in paths) {
      if (mapPath.points.length < 2) continue;

      final rightAngledPoints = _convertToRightAngledPath(mapPath.points);

      // Force Cyan color like the old app
      final pathColor = const Color(0xFF00CED1);
      final pathWidth = 8.0 / currentZoom;

      final pathPaint = Paint()
        ..color = pathColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.miter
        ..strokeWidth = pathWidth;

      final p = Path()..moveTo(rightAngledPoints.first.dx, rightAngledPoints.first.dy);
      for (int i = 1; i < rightAngledPoints.length; i++) {
        p.lineTo(rightAngledPoints[i].dx, rightAngledPoints[i].dy);
      }
      canvas.drawPath(p, pathPaint);

      // Glow effect for path
      final glowPaint = Paint()
        ..color = pathColor.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.miter
        ..strokeWidth = pathWidth + (4.0 / currentZoom);
      canvas.drawPath(p, glowPaint);
    }
  }

  void _drawLabels(Canvas canvas) {
    final drawnLabelBounds = <Rect>[];

    // Priority sort: special rooms first, then large rooms, then sub-rooms last
    final sortedRooms = List<FitRoom>.from(rooms);
    sortedRooms.sort((a, b) {
      final aSpecial = selectedRoomId == a.id ||
          startRoomId == a.id ||
          destinationRoomId == a.id ||
          highlightedRoomIds.contains(a.id);
      final bSpecial = selectedRoomId == b.id ||
          startRoomId == b.id ||
          destinationRoomId == b.id ||
          highlightedRoomIds.contains(b.id);
      if (aSpecial && !bSpecial) return -1;
      if (!aSpecial && bSpecial) return 1;

      final aSub = a.id.contains('.') || a.id.contains('_');
      final bSub = b.id.contains('.') || b.id.contains('_');
      if (!aSub && bSub) return 1;
      if (aSub && !bSub) return -1;

      final aArea = a.bounds.width * a.bounds.height;
      final bArea = b.bounds.width * b.bounds.height;
      return bArea.compareTo(aArea);
    });

    for (final room in sortedRooms) {
      final isSpecial = selectedRoomId == room.id ||
          startRoomId == room.id ||
          destinationRoomId == room.id ||
          highlightedRoomIds.contains(room.id);

      final upperId = room.id.toUpperCase();
      final isTechnicalNode = upperId.startsWith('DOOR') ||
          upperId.startsWith('NODE') ||
          upperId.startsWith('STAIR') ||
          upperId.startsWith('ELEV') ||
          upperId.startsWith('CORR');

      if (isTechnicalNode && !isSpecial) continue;
      if ((room.isCorridor || room.isStaircase) && !isSpecial) continue;

      // Sub-rooms with dot or underscore (e.g. A106.3, A106.1) are sub-partitions:
      // Don't clutter the map with sub-partition codes unless specifically selected/highlighted
      final isSubRoom = room.id.contains('.') || room.id.contains('_');
      if (isSubRoom && !isSpecial) {
        continue;
      }

      // Screen-space size threshold: room must have sufficient pixels on screen
      final onScreenWidth = room.bounds.width * currentZoom;
      final onScreenHeight = room.bounds.height * currentZoom;
      if (!isSpecial && (onScreenWidth < 18.0 || onScreenHeight < 12.0)) {
        continue;
      }

      _drawRoomLabel(canvas, room, isSpecial, drawnLabelBounds);
    }
  }

  void _drawRoomLabel(
    Canvas canvas,
    FitRoom room,
    bool isSpecial,
    List<Rect> drawnLabelBounds,
  ) {
    // Label text: WC for restrooms, V for elevators, else room id
    final labelText = room.displayLabel;
    final roomWidth = room.bounds.width;
    final roomHeight = room.bounds.height;

    // Screen-relative font size: constant crisp pixel size on screen, converted to canvas coordinates
    final screenPx = isSpecial ? 12.0 : 9.5;
    double fontSize = screenPx / currentZoom;

    // Boundary check: ensure label width does not exceed 82% of room width
    final estWidth = labelText.length * fontSize * 0.58;
    if (estWidth > roomWidth * 0.82 && !isSpecial) {
      fontSize = (roomWidth * 0.82) / (labelText.length * 0.58);
      if (fontSize * currentZoom < 7.2) {
        return;
      }
    }

    // Boundary check for height
    if (fontSize > roomHeight * 0.72 && !isSpecial) {
      fontSize = roomHeight * 0.72;
      if (fontSize * currentZoom < 7.2) {
        return;
      }
    }

    final textColor = isSpecial
        ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
        : FitMapTheme.getLabelTextColor(room, isDarkMode: isDarkMode);

    final textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: isSpecial ? FontWeight.w900 : FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final center = room.center;
    final padX = (isSpecial ? 6.0 : 2.5) / currentZoom;
    final padY = (isSpecial ? 3.0 : 1.2) / currentZoom;
    final labelRect = Rect.fromCenter(
      center: center,
      width: textPainter.width + padX * 2,
      height: textPainter.height + padY * 2,
    );

    // Collision avoidance: Never draw overlapping labels
    if (!isSpecial) {
      for (final existing in drawnLabelBounds) {
        if (labelRect.overlaps(existing)) {
          return;
        }
      }
    }

    drawnLabelBounds.add(labelRect);

    if (isSpecial) {
      final rrect = RRect.fromRectAndRadius(labelRect, Radius.circular(3.5 / currentZoom));
      final badgePaint = Paint()
        ..color = isDarkMode ? const Color(0xFF1E293B) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, badgePaint);

      final borderPaint = Paint()
        ..color = const Color(0xFF0D9488)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 / currentZoom;
      canvas.drawRRect(rrect, borderPaint);
    } else {
      // Subtle background halo for 100% legibility over fills & borders
      final haloRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: textPainter.width + (2.5 / currentZoom),
          height: textPainter.height + (1.5 / currentZoom),
        ),
        Radius.circular(1.5 / currentZoom),
      );
      final roomFill = FitMapTheme.getRoomFill(room, isDarkMode: isDarkMode);
      final haloPaint = Paint()
        ..color = roomFill.withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(haloRect, haloPaint);
    }

    final offset = Offset(
      center.dx - (textPainter.width / 2),
      center.dy - (textPainter.height / 2),
    );
    textPainter.paint(canvas, offset);
  }

  void _drawMarkers(Canvas canvas) {
    if (startRoomId != null) {
      final startRoom = rooms.where((r) => r.id == startRoomId).firstOrNull;
      if (startRoom != null) {
        _drawPinMarker(canvas, startRoom.center, const Color(0xFF10B981), 'A');
      }
    }

    if (destinationRoomId != null) {
      final destRoom = rooms.where((r) => r.id == destinationRoomId).firstOrNull;
      if (destRoom != null) {
        _drawPinMarker(canvas, destRoom.center, const Color(0xFF0D9488), 'B');
      }
    }

    if (selectedRoomId != null && selectedRoomId != startRoomId && selectedRoomId != destinationRoomId) {
      final selectedRoom = rooms.where((r) => r.id == selectedRoomId).firstOrNull;
      if (selectedRoom != null) {
        _drawPinMarker(canvas, selectedRoom.center, const Color(0xFF0D9488), '📍');
      }
    }

    for (final marker in transitionMarkers) {
      _drawTransitionMarker(canvas, marker);
    }
  }

  void _drawTransitionMarker(Canvas canvas, FloorTransitionMarker marker) {
    final point = marker.position;
    final badgeWidth = 44.0 / currentZoom;
    final badgeHeight = 22.0 / currentZoom;
    final cornerRadius = 11.0 / currentZoom;
    final strokeWidth = 1.8 / currentZoom;
    final fontSize = 10.0 / currentZoom;

    // Glowing pulse shadow
    final glowPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.35 + (0.25 * pulseValue))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 / currentZoom);
    final badgeRect = Rect.fromCenter(center: point, width: badgeWidth, height: badgeHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, Radius.circular(cornerRadius)), glowPaint);

    // Badge Fill
    final fillPaint = Paint()
      ..color = const Color(0xFF4F46E5) // Indigo
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, Radius.circular(cornerRadius)), fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, Radius.circular(cornerRadius)), borderPaint);

    // Label Text (e.g. "↑ 2F" or "↓ -1F")
    final textPainter = TextPainter(
      text: TextSpan(
        text: marker.label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(point.dx - textPainter.width / 2, point.dy - textPainter.height / 2),
    );
  }

  void _drawPinMarker(Canvas canvas, Offset point, Color color, String label) {
    // Pin marker maintains a constant 11.5px screen radius at any zoom level
    final pinRadius = 11.5 / currentZoom;
    final strokeWidth = 1.8 / currentZoom;
    final fontSize = 9.0 / currentZoom;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 / currentZoom);

    canvas.drawCircle(point.translate(0, 1.5 / currentZoom), pinRadius, shadowPaint);

    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, pinRadius, markerPaint);

    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(point, pinRadius, ringPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(point.dx - textPainter.width / 2, point.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant BuildingMapPainter oldDelegate) {
    return oldDelegate.rooms != rooms ||
        oldDelegate.footprints != footprints ||
        oldDelegate.buildingLetters != buildingLetters ||
        oldDelegate.streetLabels != streetLabels ||
        oldDelegate.highlightedRoomIds != highlightedRoomIds ||
        oldDelegate.selectedRoomId != selectedRoomId ||
        oldDelegate.startRoomId != startRoomId ||
        oldDelegate.destinationRoomId != destinationRoomId ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.paths != paths ||
        oldDelegate.transitionMarkers != transitionMarkers ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.currentZoom != currentZoom;
  }
}
