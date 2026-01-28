/// ============================================================================
/// WHATSAPP THEME - PROFESSIONAL WHATSAPP DESIGN SYSTEM
/// ============================================================================

import 'package:flutter/material.dart';

class WhatsAppTheme {
  // WhatsApp Colors
  static const Color tealGreen = Color(0xFF25D366);  // Primary green
  static const Color darkTeal = Color(0xFF075E54);   // Dark header
  static const Color lightTeal = Color(0xFF128C7E);  // Medium teal
  static const Color lightGreen = Color(0xFFDCF8C6); // Sender bubble
  static const Color white = Color(0xFFFFFFFF);      // Receiver bubble
  static const Color lightGray = Color(0xFFECE5DD);  // Background
  static const Color darkGray = Color(0xFF303030);   // Text
  static const Color blue = Color(0xFF34B7F1);       // Links/timestamps
  static const Color gray = Color(0xFF667781);       // Secondary text

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: tealGreen,
      primary: tealGreen,
      secondary: lightTeal,
      surface: Colors.white,
      background: lightGray,
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: darkTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: tealGreen,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: darkGray,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkGray,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkGray,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkGray,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkGray,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: gray,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: tealGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tealGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tealGreen,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: gray,
      size: 24,
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      color: Colors.grey[200],
      thickness: 1,
      space: 0,
    ),
    
    // Scaffold Background
    scaffoldBackgroundColor: lightGray,
  );
}
