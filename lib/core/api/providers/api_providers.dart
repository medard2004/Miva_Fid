import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../storage/token_storage.dart';
import '../storage/merchant_token_storage.dart';
import '../services/auth_service.dart';
import '../services/merchant_auth_service.dart';
import '../services/loyalty_program_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/merchant_auth_repository.dart';

/// Compteur incrémenté chaque fois que le serveur rejette le token (401).
///
/// Sert de signal montant vers la couche applicative sans que `core/` ait à
/// connaître `features/` : `app.dart` l'écoute et vide la session. Une
/// dépendance directe sur `authProvider` créerait en plus un cycle, celui-ci
/// dépendant lui-même d'`apiClientProvider`.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// Même rôle que [sessionExpiredProvider], côté session marchande.
final merchantSessionExpiredProvider = StateProvider<int>((ref) => 0);

// --- STORAGE ---
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final merchantTokenStorageProvider = Provider<MerchantTokenStorage>((ref) {
  return MerchantTokenStorage();
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

/// Dio séparé du module client : le token marchand ne doit jamais se
/// retrouver dans l'en-tête `Authorization` d'un appel client, et vice versa.
final merchantApiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(merchantTokenStorageProvider);
  return ApiClient(
    tokenStorage: tokenStorage,
    onUnauthorized: () async =>
        ref.read(merchantSessionExpiredProvider.notifier).state++,
  );
});

// --- SERVICES ---
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final merchantAuthServiceProvider = Provider<MerchantAuthService>((ref) {
  final apiClient = ref.watch(merchantApiClientProvider);
  return MerchantAuthService(apiClient);
});

// --- REPOSITORIES ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(authService, tokenStorage);
});

final merchantAuthRepositoryProvider = Provider<MerchantAuthRepository>((ref) {
  final authService = ref.watch(merchantAuthServiceProvider);
  final tokenStorage = ref.watch(merchantTokenStorageProvider);
  return MerchantAuthRepository(authService, tokenStorage);
});

final loyaltyProgramServiceProvider = Provider<LoyaltyProgramService>((ref) {
  final apiClient = ref.watch(merchantApiClientProvider);
  return LoyaltyProgramService(apiClient);
});
