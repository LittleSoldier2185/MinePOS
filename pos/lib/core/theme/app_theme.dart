import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Noto Sans Thai covers Latin + Latin Extended as well as Thai, so it's
  /// used everywhere — not just for the Thai locale — instead of switching
  /// families by language. Keeps English and Thai screens visually
  /// consistent instead of Quicksand/Montserrat English UI meeting a
  /// different font the moment the language switches.
  static ThemeData light(Locale locale) {
    final isThai = locale.languageCode == 'th';

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.terracotta,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.notoSansThaiTextTheme(),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: GoogleFonts.notoSansThai(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          // Wide Latin-style tracking distorts Thai vowel/tone-mark shaping;
          // this style is also used for translated Thai screen titles, not
          // just the untranslated "MINEPOS" brand text, so it stays
          // locale-dependent even though the font family no longer is.
          letterSpacing: isThai ? 0 : 4,
          color: AppColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.notoSansThai(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.notoSansThai(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: AppColors.ink.withValues(alpha: 0.15),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }
}
