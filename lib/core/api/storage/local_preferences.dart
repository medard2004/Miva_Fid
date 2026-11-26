import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storage/web_local_storage.dart';

class LocalPreferences {
  static const _secureStorage = FlutterSecureStorage();
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _lastRoleKey = 'last_role';
  static const String _pendingJoinCodeKey = 'pending_join_code';
  static const String _webPrefix = 'mivafid_pref_';

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      webStorageSet('$_webPrefix$key', value);
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final webKey = '$_webPrefix$key';
      final stored = webStorageGet(webKey);
      if (stored != null) return stored;
      try {
        final legacy = await _secureStorage.read(key: key);
        if (legacy != null) {
          webStorageSet(webKey, legacy);
          return legacy;
        }
      } catch (_) {}
      return null;
    }
    return _secureStorage.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      webStorageRemove('$_webPrefix$key');
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
      return;
    }
    await _secureStorage.delete(key: key);
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    await _write(_onboardingKey, value.toString());
  }

  Future<bool> hasSeenOnboarding() async {
    final value = await _read(_onboardingKey);
    return value == 'true';
  }

  /// Dernier rôle choisi sur l'écran de sélection ('client' ou 'merchant').
  Future<void> setLastRole(String role) async {
    await _write(_lastRoleKey, role);
  }

  Future<String?> getLastRole() async {
    return _read(_lastRoleKey);
  }

  /// Code QR en attente d'adhésion après une redirection OAuth / connexion.
  Future<void> setPendingJoinCode(String? code) async {
    if (code == null || code.trim().isEmpty) {
      await _delete(_pendingJoinCodeKey);
    } else {
      await _write(_pendingJoinCodeKey, code.trim());
    }
  }

  Future<String?> getPendingJoinCode() async {
    return _read(_pendingJoinCodeKey);
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

/// Miroir en mémoire du `qr_token` scanné avant authentification client.
final pendingJoinCodeProvider = StateProvider<String?>((ref) => null);

/// Consomme l'éventuel `qr_token` en attente après authentification client et
/// retourne la route cible (`/client/onboarding/join?code=...` ou
/// `/client/wallet`).
String consumePostClientAuthRoute(dynamic ref) {
  final pendingCode = ref.read(pendingJoinCodeProvider) as String?;
  if (pendingCode != null && pendingCode.isNotEmpty) {
    ref.read(pendingJoinCodeProvider.notifier).state = null;
    ref.read(localPreferencesProvider).setPendingJoinCode(null);
    return '/client/onboarding/join?code=${Uri.encodeComponent(pendingCode)}';
  }
  return '/client/wallet';
}
