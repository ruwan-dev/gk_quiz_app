import 'package:flutter/material.dart';

class AppTheme {
  static const Color vistaBlue = Color(0xFF005493);
  static const Color vistaLightBlue = Color(0xFF00A3E0);
  static const Color vistaDeepDark = Color(0xFF001A33);
  
  static const Color glassBase = Color(0x22FFFFFF); 
  static const Color glassBorder = Color(0x44FFFFFF); 

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Removed the custom Sinhala fontFamily to use system default
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: vistaBlue,
        primary: vistaBlue,
        secondary: vistaLightBlue,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: vistaDeepDark,
        foregroundColor: Colors.white,
        elevation: 15,
        centerTitle: true,
        shadowColor: Colors.black45,
        titleTextStyle: TextStyle(
          fontSize: 22, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 0.5
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vistaBlue,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: vistaLightBlue.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(
              color: Color(0x66FFFFFF), 
              width: 1.5,
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.w600
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.85), 
        elevation: 20,
        shadowColor: Colors.black38,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w900,
          color: vistaDeepDark,
          fontSize: 24,
          shadows: [Shadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1))],
        ),
        bodyLarge: TextStyle(fontSize: 18, color: Colors.black87, height: 1.4),
        labelLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}