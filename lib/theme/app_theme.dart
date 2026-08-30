import 'package:flutter/material.dart';

/// Identité visuelle 2026-08 — refonte d'après les maquettes
/// `Trésora, application financière multi-espace/Tresora Android App.dc.html`.
/// Dégradé ambre → orange en signature de marque, neutres graphite (jamais
/// de gris pur), accents recette/dépense directement repris des maquettes.
/// Remplace l'ancienne palette « tissage » (indigo/or/palme/terre).
class AppColors {
  static const fond = Color(0xFFF7F7FA);
  static const carte = Color(0xFFFFFFFF);
  static const texteEncre = Color(0xFF1A1A22);
  static const texteSecondaire = Color(0xFF6E6E7C);
  static const graphite = Color(0xFF1C1C25);
  static const or = Color(0xFFFFB300);
  static const palme = Color(0xFF21A97A);
  static const terre = Color(0xFFC2410C);
  static const alerte = Color(0xFFE14B5C);
  static const bordure = Color(0xFFE8E8EE);
  static const degradeDebut = Color(0xFFFFC220);
  static const degradeFin = Color(0xFFF26522);

  /// Teintes recette/dépense pour texte sur fond sombre (carte solde) —
  /// reprises telles quelles de la maquette, distinctes de `or`/`terre` qui
  /// sont calibrées pour un fond clair.
  static const orSurSombre = Color(0xFFFFC96B);
  static const terreSurSombre = Color(0xFFF7B39B);

  static const degradeMarque = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [degradeDebut, degradeFin],
  );
}

/// Mode sombre — mêmes rôles, valeurs assombries en gardant la teinte.
class AppColorsDark {
  static const fond = Color(0xFF101014);
  static const carte = Color(0xFF1C1C25);
  static const texteEncre = Color(0xFFF3F3F6);
  static const texteSecondaire = Color(0xFF9C9CAC);
  static const graphite = Color(0xFF0B0B0F);
  static const or = Color(0xFFFFC65C);
  static const palme = Color(0xFF3FCB9B);
  static const terre = Color(0xFFE0703A);
  static const alerte = Color(0xFFF17888);
  static const bordure = Color(0x1EFFFFFF); // rgba(255,255,255,.12)
}

/// Interface et titres : Schibsted Grotesk, une seule famille grotesque sur
/// toute la hiérarchie (400 → 800). Petits libellés/eyebrows en capitales :
/// JetBrains Mono, chasse tabulaire — jamais sur les montants eux-mêmes,
/// qui restent en Schibsted Grotesk avec chiffres tabulaires (voir la carte
/// « SOLDE » de la maquette : le libellé est en mono, le chiffre non).
class AppFonts {
  static TextStyle heading(
          {double? fontSize, FontWeight? fontWeight, Color? color}) =>
      TextStyle(
        fontFamily: 'SchibstedGrotesk',
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w800,
        letterSpacing: -.2,
        color: color,
      );

  static TextStyle montant(
          {double? fontSize, FontWeight? fontWeight, Color? color}) =>
      TextStyle(
        fontFamily: 'SchibstedGrotesk',
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w800,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -.2,
      );

  static TextStyle eyebrow({double? fontSize, Color? color}) => TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: fontSize ?? 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.4,
        color: color,
      );
}

class AppTheme {
  static ThemeData get light => _build(
        colors: (
          fond: AppColors.fond,
          carte: AppColors.carte,
          texteEncre: AppColors.texteEncre,
          texteSecondaire: AppColors.texteSecondaire,
          graphite: AppColors.graphite,
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
          graphite: AppColorsDark.graphite,
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
      Color graphite,
      Color or,
      Color palme,
      Color terre,
      Color bordure,
    }) colors,
    required Brightness brightness,
  }) {
    final baseTextTheme = (brightness == Brightness.dark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme)
        .apply(
      fontFamily: 'SchibstedGrotesk',
      bodyColor: colors.texteEncre,
      displayColor: colors.texteEncre,
    );

    final textTheme = baseTextTheme.copyWith(
      headlineLarge: AppFonts.heading(fontSize: 30, color: colors.texteEncre),
      headlineMedium: AppFonts.heading(fontSize: 24, color: colors.texteEncre),
      headlineSmall: AppFonts.heading(fontSize: 20, color: colors.texteEncre),
      titleLarge: AppFonts.heading(
          fontSize: 18, fontWeight: FontWeight.w700, color: colors.texteEncre),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: colors.terre,
        primary: colors.terre,
        secondary: colors.palme,
        error: colors.terre,
        surface: colors.carte,
      ),
      scaffoldBackgroundColor: colors.fond,
      textTheme: textTheme,
      fontFamily: 'SchibstedGrotesk',
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.graphite,
        foregroundColor: colors.fond,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.heading(fontSize: 20, color: colors.fond),
      ),
      cardTheme: CardThemeData(
        color: colors.carte,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.bordure),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.carte,
        labelStyle: TextStyle(color: colors.texteSecondaire),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.bordure, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.bordure, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.terre, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.terre,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w800, letterSpacing: .4),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.carte,
        selectedItemColor: colors.terre,
        unselectedItemColor: colors.texteSecondaire,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
