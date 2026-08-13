import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../storage/token_storage.dart';
import '../services/auth_service.dart';
import '../repositories/auth_repository.dart';

/// Compteur incrémenté chaque fois que le serveur rejette le token (401).
///
/// Sert de signal montant vers la couche applicative sans que `core/` ait à
/// connaître `features/` : `app.dart` l'écoute et vide la session. Une
/// dépendance directe sur `authProvider` créerait en plus un cycle, celui-ci
/// dépendant lui-même d'`apiClientProvider`.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

// --- STORAGE ---
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

// --- CORE ---
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    tokenStorage: tokenStorage,
    // Un 401 émet le signal ; `app.dart` s'y abonne pour vider la session,
    // après quoi la garde du routeur renvoie vers l'écran de connexion.
    onUnauthorized: () async =>
        ref.read(sessionExpiredProvider.notifier).state++,
  );
});

// --- SERVICES ---
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

// --- REPOSITORIES ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(authService, tokenStorage);
});
