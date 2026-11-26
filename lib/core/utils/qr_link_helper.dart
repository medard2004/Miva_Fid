/// Utilitaires pour construire et parser les liens intelligents des QR codes
/// commerçants.
///
/// Un QR code commerçant encode une URL web complète pointant vers le parcours
/// client (`https://<domaine>/#/client/onboarding/join?code=<qr_token>`), afin
/// qu'un scan depuis l'appareil photo natif du téléphone ouvre directement
/// l'application web, tout en restant compatible avec le scanner intégré.
class QrLinkHelper {
  static const String _defaultClientWebAppUrl = String.fromEnvironment(
    'CLIENT_WEB_APP_URL',
    defaultValue: 'https://miva-fid-client.vercel.app',
  );

  /// Retourne l'URL de la PWA Client (cible des QR codes commerçants).
  static String get webAppBaseUrl {
    return _defaultClientWebAppUrl.endsWith('/')
        ? _defaultClientWebAppUrl.substring(
            0, _defaultClientWebAppUrl.length - 1)
        : _defaultClientWebAppUrl;
  }

  /// Construit l'URL encodée dans le QR code du commerçant.
  static String buildJoinUrl(String qrToken) {
    final clean = qrToken.trim();
    if (clean.isEmpty) return '';
    return '$webAppBaseUrl/join?code=${Uri.encodeComponent(clean)}';
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

