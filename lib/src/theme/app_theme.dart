import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class AppTheme {
  static const Color primary = Color(0xFFF44336);
  static const Color accent = Color(0xFFFF5252);
  static const Color black = Colors.black;
  static const Color white = Colors.white;

  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.pottaOne(fontSize: 48),
    headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
    bodyLarge: GoogleFonts.roboto(fontSize: 16),
    bodyMedium: GoogleFonts.roboto(fontSize: 14),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    primaryColor: primary,
    scaffoldBackgroundColor: white,
    appBarTheme: const AppBarTheme(
      backgroundColor: white,
      foregroundColor: black,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: _textTheme,
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark),
    primaryColor: primary,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: _textTheme.apply(bodyColor: Colors.white),
    useMaterial3: true,
  );
}
