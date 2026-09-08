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

class SyncUpColors extends ThemeExtension<SyncUpColors> {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color surface;
  final Color background;
  final Color border;
  final Color divider;
  
  // Legacy aliases
  final Color zenGreen;
  final Color zenGreenLight;
  final Color peach;
  final Color peachLight;

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> cardShadowHover;
  final List<BoxShadow> modalShadow;

  const SyncUpColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.surface,
    required this.background,
    required this.border,
    required this.divider,
    required this.zenGreen,
    required this.zenGreenLight,
    required this.peach,
    required this.peachLight,
    required this.cardShadow,
    required this.cardShadowHover,
    required this.modalShadow,
  });

  @override
  ThemeExtension<SyncUpColors> copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? surface,
    Color? background,
    Color? border,
    Color? divider,
    Color? zenGreen,
    Color? zenGreenLight,
    Color? peach,
    Color? peachLight,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? cardShadowHover,
    List<BoxShadow>? modalShadow,
  }) {
    return SyncUpColors(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      zenGreen: zenGreen ?? this.zenGreen,
      zenGreenLight: zenGreenLight ?? this.zenGreenLight,
      peach: peach ?? this.peach,
      peachLight: peachLight ?? this.peachLight,
      cardShadow: cardShadow ?? this.cardShadow,
      cardShadowHover: cardShadowHover ?? this.cardShadowHover,
      modalShadow: modalShadow ?? this.modalShadow,
    );
  }

  @override
  ThemeExtension<SyncUpColors> lerp(ThemeExtension<SyncUpColors>? other, double t) {
    if (other is! SyncUpColors) return this;
    return SyncUpColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      zenGreen: Color.lerp(zenGreen, other.zenGreen, t)!,
      zenGreenLight: Color.lerp(zenGreenLight, other.zenGreenLight, t)!,
      peach: Color.lerp(peach, other.peach, t)!,
      peachLight: Color.lerp(peachLight, other.peachLight, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      cardShadowHover: t < 0.5 ? cardShadowHover : other.cardShadowHover,
      modalShadow: t < 0.5 ? modalShadow : other.modalShadow,
    );
  }

  static const light = SyncUpColors(
    primary: Color(0xFF0C7F89),
    primaryDark: Color(0xFF0A5F69),
    primaryLight: Color(0xFFCEEDEF),
    accent: Color(0xFF0B647A),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFF1F5F9),
    zenGreen: Color(0xFF0C7F89),
    zenGreenLight: Color(0xFFCEEDEF),
    peach: Color(0xFFE6F7FA),
    peachLight: Color(0xFFF2FCFD),
    cardShadow: [
      BoxShadow(
        color: Color(0x0A0C7F89), // primary with 0.04 alpha
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    cardShadowHover: [
      BoxShadow(
        color: Color(0x140C7F89), // primary with 0.08 alpha
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    modalShadow: [
      BoxShadow(
        color: Color(0x0F000000), // black with 0.06 alpha
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
  );

  static const dark = SyncUpColors(
    primary: Color(0xFF2DD4BF), // Teal 400
    primaryDark: Color(0xFF0F766E), // Teal 700
    primaryLight: Color(0xFF134E4A), // Teal 900
    accent: Color(0xFF38BDF8), // Sky 400
    textPrimary: Color(0xFFF8FAFC), // Slate 50
    textSecondary: Color(0xFF94A3B8), // Slate 400
    surface: Color(0xFF1E293B), // Slate 800
    background: Color(0xFF0F172A), // Slate 900
    border: Color(0xFF334155), // Slate 700
    divider: Color(0xFF1E293B), // Slate 800
    zenGreen: Color(0xFF2DD4BF),
    zenGreenLight: Color(0xFF134E4A),
    peach: Color(0xFF164E63), // Cyan 900
    peachLight: Color(0xFF083344), // Cyan 950
    cardShadow: [
      BoxShadow(
        color: Color(0x40000000), // Black 25%
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    cardShadowHover: [
      BoxShadow(
        color: Color(0x66000000), // Black 40%
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    modalShadow: [
      BoxShadow(
        color: Color(0x80000000), // Black 50%
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
  );
}

extension SyncUpThemeContextExtension on BuildContext {
  SyncUpColors get colors => Theme.of(this).extension<SyncUpColors>() ?? SyncUpColors.light;
}
