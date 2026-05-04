import re

with open('lib/theme/sync_up_theme.dart', 'r') as f:
    content = f.read()

# We want to replace textTheme() with textTheme(SyncUpColors colors)
content = content.replace('static TextTheme textTheme() {', 'static TextTheme textTheme(SyncUpColors colors) {')
content = content.replace('color: textPrimary', 'color: colors.textPrimary')
content = content.replace('color: textSecondary', 'color: colors.textSecondary')

# Replace theme getter with _buildTheme
old_theme = """  static ThemeData get theme {
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
      textTheme: textTheme(),"""

new_theme = """  static ThemeData _buildTheme(SyncUpColors colors, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [colors],
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
        primary: colors.primary,
        onPrimary: Colors.white,
        primaryContainer: colors.primaryLight,
        onPrimaryContainer: colors.textPrimary,
        secondary: colors.accent,
        onSecondary: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.border,
      ),
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme(colors),"""

content = content.replace(old_theme, new_theme)

# Now we need to replace all instances of static colors in the rest of the method
# like primary, border, surface, textPrimary, textSecondary, etc.
# We'll just do a targeted replace for the rest of the file after new_theme insertion point
idx = content.find('appBarTheme: AppBarTheme(')
if idx != -1:
    rest = content[idx:]
    rest = re.sub(r'\bprimary\b', 'colors.primary', rest)
    rest = re.sub(r'\bprimaryLight\b', 'colors.primaryLight', rest)
    rest = re.sub(r'\bborder\b', 'colors.border', rest)
    rest = re.sub(r'\btextPrimary\b', 'colors.textPrimary', rest)
    rest = re.sub(r'\btextSecondary\b', 'colors.textSecondary', rest)
    rest = re.sub(r'\bsurface\b', 'colors.surface', rest)
    rest = re.sub(r'\bdivider\b', 'colors.divider', rest)
    rest = re.sub(r'\bcardShadow\b', 'colors.cardShadow', rest)
    rest = re.sub(r'\bcardShadowHover\b', 'colors.cardShadowHover', rest)
    rest = re.sub(r'\bmodalShadow\b', 'colors.modalShadow', rest)
    content = content[:idx] + rest

# Finally add the theme and darkTheme getters at the end
content = content.replace('  }\n}\n', '  }\n\n  static ThemeData get theme => _buildTheme(SyncUpColors.light, Brightness.light);\n  static ThemeData get darkTheme => _buildTheme(SyncUpColors.dark, Brightness.dark);\n}\n')

# Add the import
if "import 'sync_up_colors.dart';" not in content:
    content = content.replace("import 'package:google_fonts/google_fonts.dart';", "import 'package:google_fonts/google_fonts.dart';\nimport 'sync_up_colors.dart';")

with open('lib/theme/sync_up_theme.dart', 'w') as f:
    f.write(content)
