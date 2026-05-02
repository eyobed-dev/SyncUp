import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static TextTheme textTheme() {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        fontSize: 28,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: textPrimary,
        fontSize: 16,
        height: 1.4,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: textPrimary,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: textSecondary,
        fontSize: 13,
        height: 1.35,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Full ThemeData.
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: textPrimary,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: const Color(0xFFEAF7F9),
        outline: border,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        iconTheme: const IconThemeData(color: primary, size: 22),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: primary.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
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
          foregroundColor: primary,
          side: const BorderSide(color: primary),
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
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary.withValues(alpha: 0.7), fontSize: 13),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: const IconThemeData(color: primary, size: 22),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 22),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(color: primary, fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 11),
        indicatorColor: primaryLight,
      ),

      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
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
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 13,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: space10, vertical: space6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),

      iconTheme: const IconThemeData(
        color: primary,
        size: 22,
      ),
    );
  }
}
