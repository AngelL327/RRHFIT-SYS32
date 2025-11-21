import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

class AppTheme {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF145A32);
  static const Color accent = Color(0xFFF57C00);
  static const Color bg = Color(0xFFF7F4F1);
  static const Color cream = Color(0xFFFBF8F6);
  static const Color blue = Color(0xFF39B5DA);
  static const Color black = Colors.black45;
  static PdfColor pdfTableHeaderBG = PdfColor.fromHex("#39b5da");
  static Color tableHeaderBG = Color(0xFF39B5DA);

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.cream,
        foregroundColor: AppTheme.black,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: cream,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        bodyMedium: const TextStyle(fontSize: 14),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.cream,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
