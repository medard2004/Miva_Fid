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

  /// Vrai pendant une déconnexion volontaire. Le serveur révoque le token dès
  /// que `/auth/logout` aboutit ; toute autre requête encore en vol à ce
  /// moment (rafraîchissement wallet, heartbeat realtime…) reçoit alors un
  /// 401 parfaitement normal mais qui, sans ce garde-fou, déclencherait à
  /// tort le toast "session expirée" en pleine déconnexion demandée par
  /// l'utilisateur.
  bool suppressUnauthorized = false;

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
    // chaque appel. On nettoie tout de suite — sauf pendant une déconnexion
    // volontaire, déjà prise en charge par [suppressUnauthorized].
    if (err.response?.statusCode == 401 && !suppressUnauthorized) {
      await tokenStorage.deleteToken();
      await onUnauthorized?.call();
    }

    super.onError(err, handler);
  }
}
