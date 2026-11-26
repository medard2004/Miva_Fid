class ApiConstants {
  /// URL de l'API Laravel.
  ///
  /// Miva_Fid ne charge pas de fichier `.env` (pas de `flutter_dotenv`) : toute
  /// la configuration passe par `--dart-define`, comme les clés Supabase dans
  /// `main.dart`. La valeur par défaut vise le backend de développement local
  /// (web sur la même machine).
  ///
  /// Pour lancer l'app avec l'URL déjà injectée (web, mobile wifi/cable,
  /// mobile données), utiliser `./scripts/dev.sh` au lieu de taper
  /// `--dart-define` à la main :
  ///
  ///     ./scripts/dev.sh              # web, wifi, cable (même réseau)
  ///     ./scripts/dev.sh tunnel       # données mobiles (tunnel ngrok)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://distract-buffalo-mockup.ngrok-free.dev/api',
  );

  static const int connectTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000;

  /// Origine de l'API sans le suffixe `/api` (ex: `https://example.ngrok-free.dev`).
  static String get apiOrigin {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return '';
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  /// Normalise toute URL média venant du backend ou d'un cache local :
  /// - force `https://` sur les domaines ngrok pour éviter le blocage Mixed Content Web
  /// - réécrit `/storage/<path>` hébergé sur notre backend/ngrok vers `/api/media/<path>`
  ///   afin de bénéficier des headers CORS Laravel
  /// - résout un chemin relatif (`logos/...`, `storage/...`) vers `apiOrigin/api/media/...`
  static String resolveMediaUrl(String? rawUrl) {
    if (rawUrl == null) return '';
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('blob:') || trimmed.startsWith('data:')) {
      return trimmed;
    }

    if (trimmed.startsWith('http://') && trimmed.contains('ngrok')) {
      trimmed = 'https://${trimmed.substring(7)}';
    }

    final origin = apiOrigin;
    final apiHost = Uri.tryParse(baseUrl)?.host ?? '';
    final parsed = Uri.tryParse(trimmed);

    if (parsed != null && parsed.hasScheme) {
      final isBackendHost = parsed.host == apiHost ||
          parsed.host.contains('ngrok') ||
          parsed.host == 'localhost' ||
          parsed.host == '127.0.0.1';
      if (isBackendHost && parsed.path.startsWith('/storage/')) {
        final mediaPath = parsed.path.substring('/storage/'.length);
        final query = parsed.hasQuery ? '?${parsed.query}' : '';
        final targetOrigin = origin.isNotEmpty
            ? origin
            : '${parsed.scheme}://${parsed.host}${parsed.hasPort ? ':${parsed.port}' : ''}';
        return '$targetOrigin/api/media/$mediaPath$query';
      }
      return trimmed;
    }

    if (origin.isEmpty) return trimmed;
    var rel = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (rel.startsWith('storage/')) {
      rel = rel.substring('storage/'.length);
    } else if (rel.startsWith('api/media/')) {
      rel = rel.substring('api/media/'.length);
    }
    return '$origin/api/media/$rel';
  }

  /// En-têtes HTTP requis lors du chargement d'images via ngrok gratuit.
  static Map<String, String>? mediaHeaders(String? url) {
    if (url != null && url.contains('ngrok')) {
      return const {'ngrok-skip-browser-warning': 'true'};
    }
    return null;
  }
}
