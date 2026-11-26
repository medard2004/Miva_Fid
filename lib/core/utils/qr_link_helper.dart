import 'package:flutter/foundation.dart';

/// Utilitaires pour construire et parser les liens intelligents des QR codes
/// commerçants.
///
/// Un QR code commerçant encode une URL web complète pointant vers le parcours
/// client (`https://<domaine>/#/client/onboarding/join?code=<qr_token>`), afin
/// qu'un scan depuis l'appareil photo natif du téléphone ouvre directement
/// l'application web, tout en restant compatible avec le scanner intégré.
class QrLinkHelper {
  static const String _defaultWebAppUrl = String.fromEnvironment(
    'WEB_APP_URL',
    defaultValue: 'https://miva-fid.vercel.app',
  );

  /// Retourne l'origine web active sur le navigateur, ou l'URL configurée
  /// via `WEB_APP_URL` sur mobile.
  static String get webAppBaseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') {
        return origin;
      }
    }
    return _defaultWebAppUrl.endsWith('/')
        ? _defaultWebAppUrl.substring(0, _defaultWebAppUrl.length - 1)
        : _defaultWebAppUrl;
  }

  /// Construit l'URL encodée dans le QR code du commerçant.
  static String buildJoinUrl(String qrToken) {
    final clean = qrToken.trim();
    if (clean.isEmpty) return '';
    return '$webAppBaseUrl/#/client/onboarding/join?code=${Uri.encodeComponent(clean)}';
  }

  /// Extrait le `qr_token` (ou code court) depuis une valeur scannée :
  /// - URL complète avec hash routing (`https://.../#/client/onboarding/join?code=TOKEN`)
  /// - URL standard (`https://.../join?code=TOKEN`)
  /// - Token brut ou code court saisi manuellement (`TOKEN`)
  static String extractQrToken(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return '';

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final directCode = uri.queryParameters['code'];
      if (directCode != null && directCode.trim().isNotEmpty) {
        return directCode.trim();
      }

      if (uri.fragment.isNotEmpty) {
        final fragmentPath =
            uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
        final fragmentUri = Uri.tryParse(fragmentPath);
        final fragmentCode = fragmentUri?.queryParameters['code'];
        if (fragmentCode != null && fragmentCode.trim().isNotEmpty) {
          return fragmentCode.trim();
        }
      }
    }

    return trimmed;
  }
}

