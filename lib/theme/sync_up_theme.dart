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
import 'sync_up_colors.dart';

/// Modern compact design system for SyncUp.
/// Blue-teal accents, tight spacing, clear visual hierarchy.
class SyncUpTheme {
  SyncUpTheme._();

  // ─── Colors ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0C7F89);       // Darker blue-teal
  static const Color primaryDark = Color(0xFF0A5F69);
  static const Color primaryLight = Color(0xFFCEEDEF);
  static const Color accent = Color(0xFF0B647A);         // Darker deep teal-blue
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Legacy aliases for widget compatibility
  static const Color zenGreen = primary;
  static const Color zenGreenLight = primaryLight;
  static const Color peach = Color(0xFFE6F7FA);  // Soft teal tint
  static const Color peachLight = Color(0xFFF2FCFD);

  // ─── Compact spacing (6px grid) ──────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // ─── Border radius (compact) ─────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;
  static const double radiusPill = 12;

  // ─── Shadows ────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ─── Typography (compact, modern) ──────────────────────────────────────
  static TextTheme textTheme(SyncUpColors colors) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        fontSize: 28,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: colors.textPrimary,
        fontSize: 16,
        height: 1.4,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: colors.textPrimary,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: colors.textSecondary,
        fontSize: 13,
        height: 1.35,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: colors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Full ThemeData.
  static ThemeData _buildTheme(SyncUpColors colors, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [colors],
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.surface,
        primaryContainer: colors.primaryLight,
        onPrimaryContainer: colors.textPrimary,
        secondary: colors.accent,
        onSecondary: colors.surface,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: border,
      ),
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme(colors),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        iconTheme: IconThemeData(color: colors.primary, size: 22),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shadowColor: colors.primary.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space10),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space10),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: space12, vertical: space10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: colors.textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.plusJakartaSans(color: colors.textSecondary.withValues(alpha: 0.7), fontSize: 13),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        selectedIconTheme: IconThemeData(color: colors.primary, size: 22),
        unselectedIconTheme: IconThemeData(color: colors.textSecondary, size: 22),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(color: colors.textSecondary, fontSize: 11),
        indicatorColor: colors.primaryLight,
      ),

      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        modalElevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSm)),
        ),
        dragHandleColor: border,
        dragHandleSize: const Size(36, 3),
        showDragHandle: true,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: space12, vertical: space6),
        minLeadingWidth: 40,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.plusJakartaSans(
          color: colors.textSecondary,
          fontSize: 13,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors.primaryLight,
        selectedColor: colors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.plusJakartaSans(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: space10, vertical: space6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),

      iconTheme: IconThemeData(
        color: colors.primary,
        size: 22,
      ),
    );
  }

  static ThemeData get theme => _buildTheme(SyncUpColors.light, Brightness.light);
  static ThemeData get darkTheme => _buildTheme(SyncUpColors.dark, Brightness.dark);
}
