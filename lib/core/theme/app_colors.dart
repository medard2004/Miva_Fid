import 'package:flutter/material.dart';

/// Palette partagée par le tunnel d'onboarding et le module commerçant.
///
/// Les tokens neutres (fond, surface, texte, bordure) sont sensibles au
/// mode sombre via [setBrightness], appelé par `appBrightnessProvider` à
/// chaque résolution du thème. Même mécanique que le design system du
/// module client (lib/features/client/core/theme/app_colors.dart) : ça
/// évite de propager `Theme.of(context)` dans la centaine de sites qui
/// référencent `AppColors.xxx` directement.
///
/// Corollaire : les écrans qui peignent avec ces tokens n'ont aucune
/// dépendance visible par Flutter, donc ils doivent observer
/// `appBrightnessProvider` pour être reconstruits sur une bascule.
///
/// L'accent de marque et les couleurs sémantiques restent identiques dans
/// les deux modes — assez saturés pour rester lisibles sur fond clair
/// comme sombre.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;

  static void setBrightness(Brightness brightness) => _brightness = brightness;

  static bool get isDark => _brightness == Brightness.dark;

  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryTint = Color(0xFFEEF2FF);
  static const merchant = Color(0xFF7C3AED);
  static const merchantDark = Color(0xFF6D28D9);
  static const merchantTint = Color(0xFFF3E8FF);
  static const success = Color(0xFF10B981);
  static const successTint = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningTint = Color(0xFFFEF3C7);
  static const warningDark = Color(0xFFD97706);
  static const danger = Color(0xFFEF4444);
  static const dangerTint = Color(0xFFFEE2E2);
  // --- Neutres, sensibles au mode ----------------------------------------
  //
  // Les constantes `...Light` / `...Dark` restent exposées : `app_theme.dart`
  // les câble directement dans ses deux `ThemeData`, où le mode est déjà
  // choisi par Flutter. Le reste du code passe par les accesseurs
  // sémantiques ci-dessous.

  static const bgLight = Color(0xFFF8F7FF);
  static const bgDark = Color(0xFF0F0E1A);

  /// Fond principal de l'app.
  static Color get background => isDark ? bgDark : bgLight;

  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E1D2E);

  /// Surface élevée — cartes, feuilles, modales.
  static Color get surface => isDark ? surfaceDark : surfaceLight;

  static const _textPrimaryLight = Color(0xFF1E1B4B);
  static const _textPrimaryDark = Color(0xFFEAE8FA);

  /// Texte principal — indigo profond en clair, quasi-blanc teinté en
  /// sombre (les neutres de cette palette tirent tous vers l'indigo).
  static Color get textPrimary =>
      isDark ? _textPrimaryDark : _textPrimaryLight;

  static const _textSecondaryLight = Color(0xFF6B7280);
  static const _textSecondaryDark = Color(0xFF9B9AB4);

  /// Texte secondaire.
  static Color get textSecondary =>
      isDark ? _textSecondaryDark : _textSecondaryLight;

  static const _borderLight = Color(0xFFE5E7EB);
  static const _borderDark = Color(0xFF2F2E45);

  /// Bordure fine (hairline) — un cran au-dessus de [surfaceDark] en
  /// sombre, pour rester visible sans trancher.
  static Color get border => isDark ? _borderDark : _borderLight;

  /// Neutral gray scale — single source of truth for every grey used across
  /// the app. Replaces one-off `Color(0xFF...)` literals scattered per screen.
  static const gray50 = Color(0xFFF8FAFC);
  static const gray100 = Color(0xFFF1F5F9);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray300 = Color(0xFFCBD5E1);
  static const gray400 = Color(0xFF94A3B8);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF475569);
  static const gray700 = Color(0xFF334155);
  static const gray800 = Color(0xFF1E293B);
  static const gray900 = Color(0xFF0F172A);
}
