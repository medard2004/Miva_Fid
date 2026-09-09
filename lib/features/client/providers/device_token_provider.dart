import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miva_fid/core/api/providers/api_providers.dart';
import 'package:miva_fid/core/services/notification_service.dart';

import 'app_providers.dart';

/// Enregistre le token FCM de l'appareil dès qu'une session client est
/// active — au login (`authProvider` passe à authentifié) comme à la
/// restauration de session au démarrage — et à chaque rotation du token
/// (`onTokenRefresh`), pour que le device reste joignable sur la durée sans
/// dupliquer l'appel dans chaque méthode de login.
class DeviceTokenNotifier {
  DeviceTokenNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, _onAuthChanged, fireImmediately: true);
    _refreshSub = NotificationService().onTokenRefresh.listen(_onTokenRefreshed);
  }

  final Ref _ref;
  StreamSubscription<String>? _refreshSub;

  void _onAuthChanged(AuthState? previous, AuthState next) {
    if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
      _registerCurrentToken();
    }
  }

  void _onTokenRefreshed(String token) {
    if (_ref.read(authProvider).isAuthenticated) {
      _register(token);
    }
  }

  Future<void> _registerCurrentToken() async {
    final token = await NotificationService().getToken();
    if (token != null) {
      await _register(token);
    }
  }

  Future<void> _register(String token) {
    return _ref
        .read(deviceTokenServiceProvider)
        .register(token, Platform.isIOS ? 'ios' : 'android');
  }

  void dispose() {
    _refreshSub?.cancel();
  }
}

final deviceTokenProvider = Provider<DeviceTokenNotifier>((ref) {
  final notifier = DeviceTokenNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
