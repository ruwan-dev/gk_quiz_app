import 'package:flutter/material.dart';

class AppTheme {
  // Dark mode සඳහා වර්ණ
  static const Color darkBg = Color(0xFF0F172A); // තද අළු/නිල්
  static const Color darkCard = Color(0xFF1E293B); // කාඩ්පත් සඳහා වර්ණය
  static const Color neonBlue = Color(0xFF38BDF8); // ප්‍රධාන ලා නිල් පැහැය
  static const Color cyanAccent = Color(0xFF22D3EE); // උප වර්ණය
  
  static const Color glassBorder = Color(0x33FFFFFF); 

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: cyanAccent,
        background: darkBg,
        surface: darkCard,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 0.5
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonBlue,
          foregroundColor: Colors.black87, 
          elevation: 8,
          shadowColor: neonBlue.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.w900
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: darkCard.withOpacity(0.85), 
        elevation: 15,
        shadowColor: Colors.black,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontSize: 24,
        ),
        bodyLarge: TextStyle(fontSize: 18, color: Colors.white70, height: 1.4),
        bodyMedium: TextStyle(color: Colors.white60),
        labelLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}