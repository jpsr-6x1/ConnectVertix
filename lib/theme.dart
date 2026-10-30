import 'package:flutter/material.dart';

// Paleta inspirada na referência da Univértix.
class CampusColors {
  static const navy = Color(0xFF35548B);
  static const navyDark = Color(0xFF233D6D);
  static const bg = Color(0xFFFAF9FD);
  static const ink = Color(0xFF161923);
  static const muted = Color(0xFF6F7280);
  static const line = Color(0xFFE5E5EC);
  static const lavenderBlue = Color(0xFFDCE5FF);
  static const peach = Color(0xFFFFDCC9);
  static const mint = Color(0xFFC7EED5);
  static const violet = Color(0xFFEBDCFF);
  static const neutral = Color(0xFFF1F0F5);
}

ThemeData campusTheme() => _createTheme(Brightness.light);
ThemeData campusDarkTheme() => _createTheme(Brightness.dark);

ThemeData _createTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: dark ? const Color(0xFF9DB8F8) : CampusColors.navy,
    brightness: brightness,
    surface: dark ? const Color(0xFF090909) : CampusColors.bg,
  );
  final bg = dark ? const Color(0xFF000000) : CampusColors.bg;
  final fill = dark ? const Color(0xFF151515) : Colors.white;
  final border = dark ? const Color(0xFF333333) : CampusColors.line;
  final primary = dark ? const Color(0xFF8FADEB) : CampusColors.navy;
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: dark ? Colors.black : Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
