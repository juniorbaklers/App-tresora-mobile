import 'package:flutter/material.dart';

/// Palette reprise de l'app web (index.html :root) pour garder une identité
/// visuelle cohérente entre le site et l'app mobile.
class AppColors {
  static const bleu = Color(0xFF16234A);
  static const bleuClair = Color(0xFF2B4C8C);
  static const vert = Color(0xFF2F6B4F);
  static const rouge = Color(0xFFA23B34);
  static const orange = Color(0xFFB8672E);
  static const or = Color(0xFFA6791E);
  static const encre = Color(0xFF151B2C);
  static const gris = Color(0xFFF6F2E8);
  static const ligne = Color(0xFFE7E0CF);
  static const carte = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bleuClair,
        primary: AppColors.bleuClair,
        secondary: AppColors.or,
        error: AppColors.rouge,
        surface: AppColors.carte,
      ),
      scaffoldBackgroundColor: AppColors.gris,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bleu,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.carte,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.ligne),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.ligne, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.ligne, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.bleuClair, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bleu,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: .3),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.carte,
        selectedItemColor: AppColors.bleu,
        unselectedItemColor: Color(0xFF7A7358),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
