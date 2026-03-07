import 'package:flutter/material.dart';

class AppTheme {
  // Landing page 3-color scheme
  static const Color color1 = Color(0xFF0F2027);
  static const Color color2 = Color(0xFF203A43);
  static const Color color3 = Color(0xFF2C5364);
  static const Color primaryRed = Color(0xFFFF4757);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      // Setting scaffold background to transparent to let the gradient show through
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Poppins',
      
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.white70),
      ),
    );
  }
}