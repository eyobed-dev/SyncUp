/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Defines data models and entities for campus_feature.
 */

import 'package:flutter/material.dart';

class BuildingFootprint {
  final String id;
  final List<Offset> points;

  BuildingFootprint({
    required this.id,
    required this.points,
  });

  factory BuildingFootprint.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final pts = <Offset>[];
    for (final p in rawPoints) {
      if (p is List && p.length >= 2) {
        pts.add(Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()));
      }
    }
    return BuildingFootprint(
      id: (json['id'] as String?) ?? '',
      points: pts,
    );
  }
}

class BuildingLetter {
  final String id;
  final String letter;
  final Offset position;

  BuildingLetter({
    required this.id,
    required this.letter,
    required this.position,
  });

  factory BuildingLetter.fromJson(Map<String, dynamic> json) {
    return BuildingLetter(
      id: (json['id'] as String?) ?? '',
      letter: (json['letter'] as String?) ?? '',
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0.0,
        (json['y'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }
}

class StreetLabel {
  final String text;
  final Offset position;
  final double angle; // In degrees, e.g. -90 for vertical

  StreetLabel({
    required this.text,
    required this.position,
    this.angle = 0.0,
  });

  factory StreetLabel.fromJson(Map<String, dynamic> json) {
    return StreetLabel(
      text: (json['text'] as String?) ?? '',
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0.0,
        (json['y'] as num?)?.toDouble() ?? 0.0,
      ),
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
