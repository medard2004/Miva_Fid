import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({
    required TokenStorage tokenStorage,
    Future<void> Function()? onUnauthorized,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      responseType: ResponseType.json,
    ));

    _dio.interceptors.add(
      AuthInterceptor(tokenStorage, onUnauthorized: onUnauthorized),
    );

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
}
