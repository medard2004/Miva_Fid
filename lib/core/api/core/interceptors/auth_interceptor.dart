import 'package:dio/dio.dart';
import '../../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorageBase tokenStorage;

  /// Appelé quand le serveur rejette le token (401). Permet à la couche
  /// applicative de vider l'état d'authentification pour que la garde du
  /// routeur renvoie vers l'écran de connexion.
  ///
  /// Optionnel : sans lui, le token est quand même purgé du stockage sécurisé.
  final Future<void> Function()? onUnauthorized;

  AuthInterceptor(this.tokenStorage, {this.onUnauthorized});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.getToken();

    // Si le token existe, l'ajouter à l'en-tête Authorization
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Demander une réponse JSON au serveur Laravel
    options.headers['Accept'] = 'application/json';

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Un 401 signifie que le token stocké n'est plus accepté (révoqué,
    // expiré, ou mot de passe réinitialisé — `resetPassword` côté Laravel
    // supprime tous les tokens du client). Le garder en mémoire laisserait
    // l'app dans un état incohérent : authentifiée en apparence, refusée à
    // chaque appel. On nettoie tout de suite.
    //
    // `/auth/logout` est exclu : un 401 y est le résultat attendu quand le
    // token était déjà invalide, et la déconnexion purge déjà le stockage.
    final isLogout = err.requestOptions.path.contains('/auth/logout');

    if (err.response?.statusCode == 401 && !isLogout) {
      await tokenStorage.deleteToken();
      await onUnauthorized?.call();
    }

    super.onError(err, handler);
  }
}
