import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const bg = Color(0xFF090909);
  static const panel = Color(0xFF101010);
  static const panel2 = Color(0xFF181818);
  static const red = Color(0xFFED1C24);
  static const text = Color(0xFFF2F2F2);
  static const accent = Color(0xFFD4D4D4);
  static const dim = Color(0xFF858585);
  static const line = Color(0xFF303030);
}

TextStyle hud(double size,
        {Color color = C.text, FontWeight w = FontWeight.w600, double ls = 1.2}) =>
    GoogleFonts.rajdhani(
        fontSize: size, color: color, fontWeight: w, letterSpacing: ls, height: 1.15);

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.red,
      onPrimary: C.bg,
      secondary: C.accent,
      onSecondary: C.bg,
      surface: C.panel,
      onSurface: C.text,
      error: C.red,
      onError: C.bg,
      outline: C.line,
    ),
    dividerColor: C.line,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: C.red,
      selectionColor: Color(0x55ED1C24),
      selectionHandleColor: C.red,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.red),
    textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme)
        .apply(bodyColor: C.text, displayColor: C.text),
  );
}
