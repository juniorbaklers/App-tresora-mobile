import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette « tissage » — indigo de teinture, safran, terre de Korhogo, palme,
/// coton écru. Reprise à l'identique de globals.css dans le dépôt tresora-app
/// (mode clair). Les neutres sont teintés chaud, jamais de gris pur.
class AppColors {
  static const fond = Color(0xFFF6F1E7);
  static const carte = Color(0xFFFFFCF6);
  static const texteEncre = Color(0xFF1B2338);
  static const texteSecondaire = Color(0xFF6E6555);
  static const indigoProfond = Color(0xFF16203A);
  static const or = Color(0xFFC88A2E);
  static const palme = Color(0xFF16694F);
  static const terre = Color(0xFFB34A24);
  static const bordure = Color(0xFFE2D9C8);
}

/// Mode sombre — mêmes rôles, valeurs de globals.css `.dark`.
class AppColorsDark {
  static const fond = Color(0xFF101827);
  static const carte = Color(0xFF17223A);
  static const texteEncre = Color(0xFFF0E8DA);
  static const texteSecondaire = Color(0xFF9B937F);
  static const indigoProfond = Color(0xFF0B1220);
  static const or = Color(0xFFE0A33E);
  static const palme = Color(0xFF3E9C7A);
  static const terre = Color(0xFFD2703F);
  static const bordure = Color(0x1CF0E8DA); // rgba(240,232,218,0.11)
}

/// Titres : Fraunces (serif variable). Interface : Plus Jakarta Sans.
/// Chiffres/tableaux : IBM Plex Mono, chasse tabulaire — jamais de police
/// par défaut sur un montant, c'est ce qui donne au tableau de bord son
/// sérieux de registre comptable plutôt qu'un look d'appli générique.
class AppFonts {
  static TextStyle heading(
          {double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color,
      ).copyWith(fontVariations: const [
        FontVariation('SOFT', 0),
        FontVariation('WONK', 1)
      ]);

  static TextStyle montant(
          {double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -.2,
      );
}

class AppTheme {
  static ThemeData get light => _build(
        colors: (
          fond: AppColors.fond,
          carte: AppColors.carte,
          texteEncre: AppColors.texteEncre,
          texteSecondaire: AppColors.texteSecondaire,
          indigoProfond: AppColors.indigoProfond,
          or: AppColors.or,
          palme: AppColors.palme,
          terre: AppColors.terre,
          bordure: AppColors.bordure,
        ),
        brightness: Brightness.light,
      );

  static ThemeData get dark => _build(
        colors: (
          fond: AppColorsDark.fond,
          carte: AppColorsDark.carte,
          texteEncre: AppColorsDark.texteEncre,
          texteSecondaire: AppColorsDark.texteSecondaire,
          indigoProfond: AppColorsDark.indigoProfond,
          or: AppColorsDark.or,
          palme: AppColorsDark.palme,
          terre: AppColorsDark.terre,
          bordure: AppColorsDark.bordure,
        ),
        brightness: Brightness.dark,
      );

  static ThemeData _build({
    required ({
      Color fond,
      Color carte,
      Color texteEncre,
      Color texteSecondaire,
      Color indigoProfond,
      Color or,
      Color palme,
      Color terre,
      Color bordure,
    }) colors,
    required Brightness brightness,
  }) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    ).apply(bodyColor: colors.texteEncre, displayColor: colors.texteEncre);

    final textTheme = baseTextTheme.copyWith(
      headlineLarge: AppFonts.heading(fontSize: 30, color: colors.texteEncre),
      headlineMedium: AppFonts.heading(fontSize: 24, color: colors.texteEncre),
      headlineSmall: AppFonts.heading(fontSize: 20, color: colors.texteEncre),
      titleLarge: AppFonts.heading(
          fontSize: 18, fontWeight: FontWeight.w600, color: colors.texteEncre),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: colors.or,
        primary: colors.or,
        secondary: colors.palme,
        error: colors.terre,
        surface: colors.carte,
      ),
      scaffoldBackgroundColor: colors.fond,
      textTheme: textTheme,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.indigoProfond,
        foregroundColor: colors.fond,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.heading(fontSize: 20, color: colors.fond),
      ),
      cardTheme: CardThemeData(
        color: colors.carte,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.bordure),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.carte,
        labelStyle: TextStyle(color: colors.texteSecondaire),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.bordure, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.bordure, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.or, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.indigoProfond,
          foregroundColor: colors.fond,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, letterSpacing: .3),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.carte,
        selectedItemColor: colors.or,
        unselectedItemColor: colors.texteSecondaire,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
