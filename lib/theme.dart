import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const bg = Color(0xFF07090C);
  static const panel = Color(0xFF0E1217);
  static const panel2 = Color(0xFF151B22);
  static const yellow = Color(0xFFFCEE09);
  static const cyan = Color(0xFF5EF6FF);
  static const red = Color(0xFFFF003C);
  static const dim = Color(0xFF6B7885);
  static const text = Color(0xFFE6F1F5);
  static const line = Color(0xFF1F2933);
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
        primary: C.yellow, secondary: C.cyan, surface: C.panel, error: C.red),
    textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme)
        .apply(bodyColor: C.text, displayColor: C.text),
  );
}
