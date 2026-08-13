class ApiConstants {
  /// URL de l'API Laravel.
  ///
  /// Miva_Fid ne charge pas de fichier `.env` (pas de `flutter_dotenv`) : toute
  /// la configuration passe par `--dart-define`, comme les clés Supabase dans
  /// `main.dart`. La valeur par défaut vise le backend de développement local.
  ///
  ///     flutter run --dart-define=API_BASE_URL=http://192.168.1.83:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.83:8000/api',
  );

  static const int connectTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000;
}
