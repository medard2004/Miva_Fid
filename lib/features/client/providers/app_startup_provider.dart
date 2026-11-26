import 'dart:async';
import 'package:flutter/foundation.dart';
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

Future<T> _safeRead<T>(Future<T> future, T fallback, String label) async {
  try {
    return await future;
  } catch (e) {
    debugPrint('[app_startup_provider] Erreur lecture $label: $e');
    return fallback;
  }
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
  final authRepository = ref.read(authRepositoryProvider);
  final merchantAuthRepository = ref.read(merchantAuthRepositoryProvider);
  final cache = ref.read(offlineCacheServiceProvider);

  // Lectures locales parallèles (isolées individuellement pour qu'une erreur de
  // préférence n'empêche jamais la restauration de session).
  final results = await Future.wait<dynamic>([
    _safeRead(prefs.hasSeenOnboarding(), false, 'hasSeenOnboarding'),
    _safeRead<String?>(prefs.getLastRole(), null, 'lastRole'),
    _safeRead<String?>(prefs.getPendingJoinCode(), null, 'pendingJoinCode'),
    _safeRead(authRepository.isLoggedIn(), false, 'clientIsLoggedIn'),
    _safeRead(merchantAuthRepository.isLoggedIn(), false, 'merchantIsLoggedIn'),
  ]);

  final hasSeenOnboarding = results[0] as bool;
  final lastRole = results[1] as String?;
  final storedPendingCode = results[2] as String?;
  final isClientLoggedIn = results[3] as bool;
  final isMerchantLoggedIn = results[4] as bool;

  ref.read(hasSeenOnboardingProvider.notifier).state = hasSeenOnboarding;

  if (ref.read(pendingJoinCodeProvider) == null &&
      storedPendingCode != null &&
      storedPendingCode.isNotEmpty) {
    ref.read(pendingJoinCodeProvider.notifier).state = storedPendingCode;
  }

  // Attache le listener avant toute restauration de session, pour capter
  // aussi bien un login frais qu'une session déjà valide au démarrage.
  ref.read(deviceTokenProvider);

  // ───────────────────────────────────────────────────────────────────────────
  // CLIENT : Restauration Cache-First (non-bloquante si cache disponible)
  // ───────────────────────────────────────────────────────────────────────────
  if (isClientLoggedIn) {
    final cachedUserJson = await cache.getClientUser();
    var restoredFromCache = false;
    if (cachedUserJson != null) {
      try {
        ref.read(authProvider.notifier).setAuthenticated(
              AppUser.fromJson(cachedUserJson),
            );
        restoredFromCache = true;
        unawaited(ref.read(walletProvider.notifier).loadFromCache().catchError((e) {
          debugPrint('[app_startup_provider] Erreur chargement wallet cache: $e');
        }));
      } catch (e) {
        debugPrint('[app_startup_provider] Erreur parsing client user cache: $e');
      }
    }

    Future<void> refreshClientSession() async {
      try {
        final freshUser = await authRepository
            .getMe()
            .timeout(Duration(seconds: restoredFromCache ? 10 : 15));
        ref.read(authProvider.notifier).setAuthenticated(freshUser);
        unawaited(ref.read(walletProvider.notifier).loadMine().catchError((e) {
          debugPrint('[app_startup_provider] Erreur rafraîchissement wallet réseau: $e');
        }));
      } on TimeoutException {
        debugPrint('[app_startup_provider] Timeout validation réseau client -> conservation session cache');
      } on UnauthorizedException {
        await cache.clearClientData();
        await ref.read(authProvider.notifier).signOut();
      } catch (e) {
        debugPrint('[app_startup_provider] Erreur validation réseau client: $e');
      }
    }

    if (restoredFromCache) {
      unawaited(refreshClientSession());
    } else {
      await refreshClientSession();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MARCHAND : Restauration Cache-First (non-bloquante si cache disponible)
  // ───────────────────────────────────────────────────────────────────────────
  if (isMerchantLoggedIn) {
    final cachedMerchantJson = await cache.getMerchantAccount();
    var restoredFromCache = false;
    if (cachedMerchantJson != null) {
      try {
        ref.read(merchantAuthProvider.notifier).setAuthenticated(
              RestaurantAccount.fromJson(cachedMerchantJson),
            );
        restoredFromCache = true;
      } catch (e) {
        debugPrint('[app_startup_provider] Erreur parsing merchant account cache: $e');
      }
    }

    Future<void> refreshMerchantSession() async {
      try {
        final freshMerchant = await merchantAuthRepository
            .getMe()
            .timeout(Duration(seconds: restoredFromCache ? 10 : 15));
        ref.read(merchantAuthProvider.notifier).setAuthenticated(freshMerchant);
      } on TimeoutException {
        debugPrint('[app_startup_provider] Timeout validation réseau merchant -> conservation session cache');
      } on UnauthorizedException {
        await cache.clearMerchantData();
        await ref.read(merchantAuthProvider.notifier).signOut();
      } catch (e) {
        debugPrint('[app_startup_provider] Erreur validation réseau merchant: $e');
      }
    }

    if (restoredFromCache) {
      unawaited(refreshMerchantSession());
    } else {
      await refreshMerchantSession();
    }
  }

  return AppStartupState(hasSeenOnboarding: hasSeenOnboarding, lastRole: lastRole);
});
