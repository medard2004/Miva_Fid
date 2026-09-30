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
}
