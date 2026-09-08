/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Defines data models and entities for map_path.
 */

import 'package:flutter/material.dart';

enum PathStyle {
  solid,
  dashed,
  dotted,
}

class MapPath {
  final List<Offset> points;
  final Color color;
  final double width;
  final PathStyle style;
  final String? id;

  const MapPath({
    required this.points,
    required this.color,
    this.width = 4.0,
    this.style = PathStyle.solid,
    this.id,
  });

  factory MapPath.navigation({
    required List<Offset> points,
    Color color = const Color(0xFF0D9488), // Teal accent
    String? id,
  }) {
    return MapPath(
      points: points,
      color: color,
      width: 6.0,
      style: PathStyle.solid,
      id: id,
    );
  }
}

class NavigationInstruction {
  final int stepNumber;
  final String text;
  final IconData icon;
  final String floor;
  final String? targetRoomId;

  const NavigationInstruction({
    required this.stepNumber,
    required this.text,
    required this.icon,
    required this.floor,
    this.targetRoomId,
  });
}

class FloorTransitionMarker {
  final Offset position;
  final String label;
  final String targetFloor;
  final bool isUp;
  final String roomId;

  const FloorTransitionMarker({
    required this.position,
    required this.label,
    required this.targetFloor,
    required this.isUp,
    required this.roomId,
  });
}

