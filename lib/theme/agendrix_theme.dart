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
import 'package:google_fonts/google_fonts.dart';

/// Agendrix design system tokens.
/// Zen green primary, light peach accents, clean professional UI.
class AgendrixTheme {
  AgendrixTheme._();

  // ─── Colors ─────────────────────────────────────────────────────────────
  static const Color zenGreen = Color(0xFF6C9B88);
  static const Color zenGreenDark = Color(0xFF5A8A76);
  static const Color zenGreenLight = Color(0xFFE8F5EE);
  static const Color peach = Color(0xFFFFE5D9);
  static const Color peachLight = Color(0xFFFFF0EB);
  static const Color textPrimary = Color(0xFF2D4A3E);
  static const Color textSecondary = Color(0xFF5C6B63);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAFAF8);
  static const Color border = Color(0xFFE0E8E4);
  static const Color divider = Color(0xFFEEF2F0);

  // ─── Spacing (8px grid) ────────────────────────────────────────────────
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;

  // ─── Border radius ──────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 999;

  // ─── Shadows (soft, subtle) ──────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: zenGreen.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: zenGreen.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  // ─── Typography ─────────────────────────────────────────────────────────
  static TextTheme textTheme() {
    final base = GoogleFonts.interTextTheme();
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: textPrimary,
        fontSize: 18,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: textSecondary,
        fontSize: 14,
        height: 1.45,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Full Agendrix ThemeData.
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.light(
        primary: zenGreen,
        onPrimary: Colors.white,
        primaryContainer: zenGreenLight,
        onPrimaryContainer: textPrimary,
        secondary: peach,
        onSecondary: textPrimary,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: const Color(0xFFF5F7F6),
        outline: border,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme(),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: zenGreen, size: 24),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards – soft shadow, rounded, subtle border
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: zenGreen.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: zenGreen.withValues(alpha: 0.12)),
        ),
      ),

      // Buttons – pill shape, filled primary
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: zenGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: space24, vertical: space12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: zenGreen,
          side: const BorderSide(color: zenGreen),
          padding: const EdgeInsets.symmetric(horizontal: space24, vertical: space12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: zenGreen,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: zenGreen, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textSecondary.withValues(alpha: 0.7), fontSize: 14),
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: zenGreen,
        unselectedLabelColor: textPrimary.withValues(alpha: 0.6),
        indicatorColor: zenGreen,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      // Bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: zenGreen,
        unselectedItemColor: textPrimary.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // Navigation rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: const IconThemeData(color: zenGreen, size: 24),
        unselectedIconTheme: IconThemeData(color: textPrimary.withValues(alpha: 0.6), size: 24),
        selectedLabelTextStyle: GoogleFonts.inter(color: zenGreen, fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelTextStyle: GoogleFonts.inter(color: textPrimary.withValues(alpha: 0.6), fontSize: 12),
        indicatorColor: zenGreenLight,
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 0,
        modalElevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        dragHandleColor: border,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: space16, vertical: space8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: zenGreenLight,
        selectedColor: zenGreen.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: zenGreen,
        size: 24,
      ),
    );
  }
}
