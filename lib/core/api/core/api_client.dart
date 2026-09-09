import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  ApiClient({
    required TokenStorageBase tokenStorage,
    Future<void> Function()? onUnauthorized,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      responseType: ResponseType.json,
      // Le backend de dev par défaut est un tunnel ngrok gratuit : sans ce
      // header, ngrok sert sa page d'avertissement HTML à toute requête
      // portant un User-Agent de navigateur — systématiquement le cas sur
      // Flutter Web — au lieu de la relayer à Laravel. Inoffensif sur tout
      // autre backend (header simplement ignoré).
      headers: const {'ngrok-skip-browser-warning': 'true'},
    ));

    _authInterceptor = AuthInterceptor(tokenStorage, onUnauthorized: onUnauthorized);
    _dio.interceptors.add(_authInterceptor);

    // Journalisation réservée au développement. En release, `requestBody`
    // recracherait les mots de passe en clair et `responseBody` les tokens
    // Sanctum dans les logs de l'appareil.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  /// Coupe le signal "session expirée" le temps d'une déconnexion volontaire
  /// — voir [AuthInterceptor.suppressUnauthorized].
  set suppressUnauthorized(bool value) => _authInterceptor.suppressUnauthorized = value;
  bool get suppressUnauthorized => _authInterceptor.suppressUnauthorized;
}
