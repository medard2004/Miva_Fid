import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Échelle typographique — Cormorant (serif éditorial) pour les
/// titres, Inter pour le reste de l'UI, plus IBM Plex Mono en accent
/// ponctuel pour les données chiffrées (soldes, identifiants de carte,
/// code OTP).
class AppTextStyles {
  AppTextStyles._();

  // --- Display / titres — Cormorant, serif éditorial ---

  /// Titre pleine page des écrans du parcours de compte (connexion,
  /// inscription, mot de passe).
  ///
  /// Ces écrans n'affichent qu'une seule accroche, sans concurrence visuelle :
  /// elle porte donc plus grand que [displayXL], réservé aux titres de
  /// contenu où d'autres éléments coexistent.
  static TextStyle displayHero({Color? color}) => GoogleFonts.cormorant(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
        height: 1.05,
        letterSpacing: -0.5,
      );

  static TextStyle displayXL({Color? color}) => GoogleFonts.cormorant(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
        height: 1.15,
        letterSpacing: -0.2,
      );

  static TextStyle displayLarge({Color? color}) => GoogleFonts.cormorant(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
        height: 1.15,
        letterSpacing: -0.1,
      );

  /// Titre de page d'authentification : uniforme pour connexion,
  /// inscription, récupération de mot de passe et autres écrans liés à
  /// l'identification du client.
  static TextStyle authTitle({Color? color}) => GoogleFonts.cormorant(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
        height: 1.1,
        letterSpacing: -0.2,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.cormorant(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.ink,
        height: 1.25,
      );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.cormorant(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.ink,
        height: 1.3,
      );

  // --- Titres client standard (Cormorant) ---
  static TextStyle h1({Color? color}) => GoogleFonts.cormorant(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
      );

  static TextStyle h2({Color? color}) => GoogleFonts.cormorant(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
      );

  static TextStyle h3({Color? color}) => GoogleFonts.cormorant(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.ink,
      );

  static TextStyle labelBold({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
      );

  // --- Corps / UI — Inter, poids réguliers ---

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.ink,
        height: 1.45,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.ink,
        height: 1.45,
      );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.ink,
        height: 1.45,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: (color ?? AppColors.ink).withValues(alpha: 0.68),
        height: 1.35,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: (color ?? AppColors.ink).withValues(alpha: 0.68),
        height: 1.35,
      );

  static TextStyle label({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.ink,
        letterSpacing: 0.1,
      );

  /// Label mono majuscule — éléments de section, statuts, timers.
  static TextStyle eyebrow({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.ink,
        letterSpacing: 0.8,
      );

  // --- Chiffres / données — IBM Plex Mono, tracking modéré ---

  static TextStyle monoLarge({Color? color}) => GoogleFonts.ibmPlexMono(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.ink,
        letterSpacing: 0.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle monoMedium({Color? color}) => GoogleFonts.ibmPlexMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.ink,
        letterSpacing: 0.6,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle monoSmall({Color? color}) => GoogleFonts.ibmPlexMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: (color ?? AppColors.ink).withValues(alpha: 0.75),
        letterSpacing: 0.8,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
