import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalPreferences {
  static const _secureStorage = FlutterSecureStorage();
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _lastRoleKey = 'last_role';

  Future<void> setHasSeenOnboarding(bool value) async {
    await _secureStorage.write(key: _onboardingKey, value: value.toString());
  }

  Future<bool> hasSeenOnboarding() async {
    final value = await _secureStorage.read(key: _onboardingKey);
    return value == 'true';
  }

  /// Dernier rôle choisi sur l'écran de sélection ('client' ou 'merchant').
  Future<void> setLastRole(String role) async {
    await _secureStorage.write(key: _lastRoleKey, value: role);
  }

  Future<String?> getLastRole() async {
    return _secureStorage.read(key: _lastRoleKey);
  }
}

final localPreferencesProvider = Provider<LocalPreferences>((ref) {
  return LocalPreferences();
});

/// Miroir en mémoire de `has_seen_onboarding`, tenu à jour dès la fin d'un
/// carrousel d'intro (client ou marchand) — sans lui, l'écran de sélection
/// de rôle ne verrait la mise à jour qu'au prochain démarrage de l'app (le
/// stockage sécurisé n'étant relu qu'au boot par `appStartupProvider`), et
/// re-proposerait l'intro à un retour en arrière dans la même session.
final hasSeenOnboardingProvider = StateProvider<bool>((ref) => false);
