import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../core/api/storage/local_preferences.dart';
import 'app_providers.dart';

/// Résultat de l'amorçage, lu par l'écran de démarrage pour choisir sa
/// destination.
class AppStartupState {
  /// Faux au tout premier lancement : le carrousel d'introduction doit alors
  /// s'afficher avant l'écran de connexion.
  final bool hasSeenOnboarding;

  const AppStartupState({required this.hasSeenOnboarding});
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

  final authRepository = ref.read(authRepositoryProvider);

  if (await authRepository.isLoggedIn()) {
    try {
      ref.read(authProvider.notifier).setAuthenticated(
            await authRepository.getMe(),
          );
    } catch (_) {
      // Token refusé ou backend injoignable : on repart déconnecté plutôt que
      // de laisser l'utilisateur sur un écran bloqué.
      await ref.read(authProvider.notifier).signOut();
    }
  }

  return AppStartupState(hasSeenOnboarding: hasSeenOnboarding);
});
