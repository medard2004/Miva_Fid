import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/api/providers/api_providers.dart';
import '../../../core/api/storage/local_preferences.dart';
import '../../../core/cache/offline_cache_service.dart';
import '../../merchant/models/restaurant_account.dart';
import '../../merchant/providers/merchant_auth_provider.dart';
import '../models/user.dart';
import 'app_providers.dart';
import 'device_token_provider.dart';
import 'wallet_provider.dart';

/// Résultat de l'amorçage, lu par l'écran de démarrage pour choisir sa
/// destination.
class AppStartupState {
  /// Faux au tout premier lancement : le carrousel d'introduction doit alors
  /// s'afficher avant l'écran de connexion.
  final bool hasSeenOnboarding;

  /// Dernier rôle choisi sur l'écran de sélection ('client' ou 'merchant'),
  /// null si jamais choisi.
  final String? lastRole;

  const AppStartupState({required this.hasSeenOnboarding, this.lastRole});
}

/// Restaure la session avant le premier rendu.
///
/// Approche « Cache-First, Network-Refresh » :
/// 1. Si un token est présent, on restaure immédiatement les données du profil
///    et du wallet depuis le cache local SQLite, afin de rendre l'application
///    accessible instantanément (même totalement hors-ligne).
/// 2. En arrière-plan ou parallèlement, on interroge `GET /auth/me` pour rafraîchir
///    les données et valider le token.
/// 3. Seul un rejet explicite du token (401 Unauthorized) déconnecte la session.
///    Une erreur réseau (timeout, absence de connexion) préserve la session active
///    avec les données locales.
final appStartupProvider = FutureProvider<AppStartupState>((ref) async {
  final prefs = ref.read(localPreferencesProvider);
  final hasSeenOnboarding = await prefs.hasSeenOnboarding();
  ref.read(hasSeenOnboardingProvider.notifier).state = hasSeenOnboarding;
  final lastRole = await prefs.getLastRole();

  // Attache le listener avant toute restauration de session, pour capter
  // aussi bien un login frais qu'une session déjà valide au démarrage.
  ref.read(deviceTokenProvider);

  final authRepository = ref.read(authRepositoryProvider);
  final merchantAuthRepository = ref.read(merchantAuthRepositoryProvider);
  final cache = ref.read(offlineCacheServiceProvider);

  // ───────────────────────────────────────────────────────────────────────────
  // CLIENT : Restauration Cache-First
  // ───────────────────────────────────────────────────────────────────────────
  if (await authRepository.isLoggedIn()) {
    // 1. Restauration immédiate depuis le cache local (si disponible)
    final cachedUserJson = await cache.getClientUser();
    if (cachedUserJson != null) {
      try {
        ref.read(authProvider.notifier).setAuthenticated(
              AppUser.fromJson(cachedUserJson),
            );
        try {
          await ref.read(walletProvider.notifier).loadFromCache();
        } catch (_) {}
      } catch (_) {}
    }

    // 2. Validation / rafraîchissement réseau
    try {
      final freshUser = await authRepository.getMe();
      ref.read(authProvider.notifier).setAuthenticated(freshUser);

      // Repeuple le wallet avec les données fraîches du serveur
      try {
        await ref.read(walletProvider.notifier).loadMine();
      } catch (_) {}
    } on UnauthorizedException {
      // Token réellement rejeté par le serveur (401) : purge et déconnexion
      await cache.clearClientData();
      await ref.read(authProvider.notifier).signOut();
    } catch (_) {
      // Erreur réseau (hors-ligne, timeout) :
      // On conserve la session restaurée depuis le cache !
      if (ref.read(authProvider).isAuthenticated) {
        try {
          await ref.read(walletProvider.notifier).loadFromCache();
        } catch (_) {}
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MARCHAND : Restauration Cache-First
  // ───────────────────────────────────────────────────────────────────────────
  if (await merchantAuthRepository.isLoggedIn()) {
    // 1. Restauration immédiate depuis le cache local (si disponible)
    final cachedMerchantJson = await cache.getMerchantAccount();
    if (cachedMerchantJson != null) {
      try {
        ref.read(merchantAuthProvider.notifier).setAuthenticated(
              RestaurantAccount.fromJson(cachedMerchantJson),
            );
      } catch (_) {}
    }

    // 2. Validation / rafraîchissement réseau
    try {
      final freshMerchant = await merchantAuthRepository.getMe();
      ref.read(merchantAuthProvider.notifier).setAuthenticated(freshMerchant);
    } on UnauthorizedException {
      // Token réellement rejeté (401)
      await cache.clearMerchantData();
      await ref.read(merchantAuthProvider.notifier).signOut();
    } catch (_) {
      // Erreur réseau : on conserve la session restaurée depuis le cache !
    }
  }

  return AppStartupState(hasSeenOnboarding: hasSeenOnboarding, lastRole: lastRole);
});
