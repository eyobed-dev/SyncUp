/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Configures visual styling and theme constants.
 */

import 'package:flutter/material.dart';
import '../models/fit_room.dart';

/// Official FIT VUT Map Color Palette
/// Directly derived from the official FIT VUT web map stylesheet (fit.vut.cz)
class FitMapTheme {
  FitMapTheme._();

  // 1. Official Room Fills (Light Mode)
  static const Color lectureBlue = Color(0xFF80D3F0);     // Lecture, Labs, Study, Library (.room.laboratory, .lecture, .library, .study)
  static const Color officeYellow = Color(0xFFFFFF7F);    // Classrooms, Offices (.room.office)
  static const Color departmentOrange = Color(0xFFED913F);// Department offices, Common, Technical, Archives (.room.other, .common, .cellar)
  static const Color toiletsGreen = Color(0xFF3FBF3F);    // Restrooms (.room.toilets)
  static const Color corridorGray = Color(0xFF8D8D8D);    // Corridors, Hallways, Respiria (.room.corridor)
  static const Color stairsDarkGray = Color(0xFF4D4D4D);  // Staircases (.room.stairs)
  static const Color elevatorSlate = Color(0xFF676767);   // Elevators (.room.elevator)

  // 2. Official Room Fills (Dark Mode Adapted)
  static const Color lectureBlueDark = Color(0xFF0369A1);
  static const Color officeYellowDark = Color(0xFFB45309);
  static const Color departmentOrangeDark = Color(0xFFC2410C);
  static const Color toiletsGreenDark = Color(0xFF15803D);
  static const Color corridorGrayDark = Color(0xFF334155);
  static const Color stairsDarkGrayDark = Color(0xFF1E2025);
  static const Color elevatorSlateDark = Color(0xFF27272A);

  // 3. Campus Features
  static const Color footprintLight = Color(0xFFE8EAEA);  // Building silhouettes & walkways
  static const Color footprintDark = Color(0xFF1E293B);
  static const Color footprintBorderLight = Color(0xFFD6DADA);
  static const Color footprintBorderDark = Color(0xFF334155);

  static const Color buildingWingLetter = Color(0xFF00A9E0); // Bright FIT Cyan-Blue (text.building)
  static const Color streetLabelLight = Color(0xFF757575);   // Street names in gray (text.street)
  static const Color streetLabelDark = Color(0xFF94A3B8);

  static const Color roomBorderLight = Color(0xFF2B2D31);    // 1px room outlines
  static const Color roomBorderDark = Color(0xFF64748B);

  /// Returns the room fill color based on roomType and theme mode
  static Color getRoomFill(FitRoom room, {required bool isDarkMode}) {
    switch (room.roomType.toLowerCase()) {
      case 'lecture':
      case 'laboratory':
      case 'library':
      case 'study':
        return isDarkMode ? lectureBlueDark : lectureBlue;
      case 'office':
        return isDarkMode ? officeYellowDark : officeYellow;
      case 'toilets':
        return isDarkMode ? toiletsGreenDark : toiletsGreen;
      case 'corridor':
        return isDarkMode ? corridorGrayDark : corridorGray;
      case 'stairs':
        return isDarkMode ? stairsDarkGrayDark : stairsDarkGray;
      case 'elevator':
        return isDarkMode ? elevatorSlateDark : elevatorSlate;
      case 'other':
      case 'common':
      case 'cellar':
      default:
        return isDarkMode ? departmentOrangeDark : departmentOrange;
    }
  }

  /// Returns the optimal readable text color for room labels
  static Color getLabelTextColor(FitRoom room, {required bool isDarkMode}) {
    final t = room.roomType.toLowerCase();
    if (t == 'stairs' || t == 'elevator') {
      return Colors.white;
    }
    if (isDarkMode) {
      return Colors.white;
    }
    // In light mode, black text creates high contrast against yellow, cyan, orange, green, and gray
    return const Color(0xFF0F172A);
  }
}
