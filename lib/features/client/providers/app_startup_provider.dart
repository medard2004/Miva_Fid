import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/api/providers/api_providers.dart';
import '../../../core/api/storage/local_preferences.dart';
import '../../merchant/providers/merchant_auth_provider.dart';
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
/// Le token vit dans le stockage sécurisé, mais sa seule présence ne prouve
/// rien : il a pu être révoqué côté serveur (déconnexion depuis un autre
/// appareil, réinitialisation du mot de passe, expiration). On le confronte
/// donc à `GET /auth/me`, et on ne repeuple la session que si le serveur
/// l'accepte. En cas de refus, on nettoie pour éviter une session fantôme
/// qui échouerait à chaque appel suivant.
final appStartupProvider = FutureProvider<AppStartupState>((ref) async {
  final prefs = ref.read(localPreferencesProvider);
  final hasSeenOnboarding = await prefs.hasSeenOnboarding();
  ref.read(hasSeenOnboardingProvider.notifier).state = hasSeenOnboarding;
  final lastRole = await prefs.getLastRole();

  // Attache le listener avant toute restauration de session, pour capter
  // aussi bien un login frais qu'une session déjà valide au démarrage.
  ref.read(deviceTokenProvider);

  final authRepository = ref.read(authRepositoryProvider);

  if (await authRepository.isLoggedIn()) {
    try {
      ref.read(authProvider.notifier).setAuthenticated(
            await authRepository.getMe(),
          );
      // Repeuple le wallet avant que l'écran de démarrage ne route vers lui
      // — sinon la pile affiche brièvement l'état "aucune carte" pendant
      // l'appel réseau. Un échec ici (backend injoignable) ne doit pas
      // empêcher l'accès au wallet : les cartes resteront simplement vides
      // jusqu'au prochain chargement réussi.
      try {
        await ref.read(walletProvider.notifier).loadMine();
      } catch (_) {}
    } on UnauthorizedException {
      // Token vraiment rejeté par le serveur : on repart déconnecté plutôt
      // que de laisser l'utilisateur sur un écran bloqué. (L'intercepteur a
      // déjà purgé le token sur le 401 — `signOut()` aligne juste l'état
      // `authProvider` en mémoire dessus.)
      await ref.read(authProvider.notifier).signOut();
    } catch (_) {
      // Backend injoignable (réseau instable au démarrage à froid, timeout) :
      // le token reste valide, on ne déconnecte pas. La session reste
      // simplement non authentifiée pour cette ouverture ; le prochain
      // lancement retentera avec le même token.
    }
  }

  final merchantAuthRepository = ref.read(merchantAuthRepositoryProvider);

  if (await merchantAuthRepository.isLoggedIn()) {
    try {
      ref.read(merchantAuthProvider.notifier).setAuthenticated(
            await merchantAuthRepository.getMe(),
          );
    } catch (_) {
      await ref.read(merchantAuthProvider.notifier).signOut();
    }
  }

  return AppStartupState(hasSeenOnboarding: hasSeenOnboarding, lastRole: lastRole);
});
