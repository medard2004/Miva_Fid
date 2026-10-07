import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miva_fid/core/api/providers/api_providers.dart';
import 'package:miva_fid/core/services/notification_service.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';

import 'app_providers.dart';

/// Enregistre le token FCM de l'appareil dès qu'une session client **ou
/// marchand** est active — au login (`authProvider` / `merchantAuthProvider`
/// passe à authentifié), à la restauration de session au démarrage, et à
/// chaque rotation du token (`onTokenRefresh`).
///
/// Côté marchand, cela garantit que le token FCM est ré-enregistré
/// lorsqu'un établissement est réactivé dans Filament et que le marchand
/// actualise son écran (pull-to-refresh → `refreshFromApi()` → state change
/// → listener ici).
class DeviceTokenNotifier {
  DeviceTokenNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, _onAuthChanged, fireImmediately: true);
    _ref.listen<MerchantAuthState>(merchantAuthProvider, _onMerchantAuthChanged,
        fireImmediately: true);
    _refreshSub = NotificationService().onTokenRefresh.listen(_onTokenRefreshed);
  }

  final Ref _ref;
  StreamSubscription<String>? _refreshSub;

  void _onAuthChanged(AuthState? previous, AuthState next) {
    if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
      _registerCurrentToken();
    }
  }

  void _onMerchantAuthChanged(
      MerchantAuthState? previous, MerchantAuthState next) {
    if (next.isAuthenticated &&
        (previous == null || !previous.isAuthenticated)) {
      _registerCurrentToken();
    }
  }

  void _onTokenRefreshed(String token) {
    final isClientAuth = _ref.read(authProvider).isAuthenticated;
    final isMerchantAuth = _ref.read(merchantAuthProvider).isAuthenticated;
    if (isClientAuth || isMerchantAuth) {
      _register(token).catchError((e) {
        debugPrint('[device_token_provider] Erreur refresh token: $e');
      });
    }
  }

  /// Ré-enregistre le token FCM actuel — appelé au login et exposé
  /// publiquement pour le pull-to-refresh marchand après une réactivation.
  Future<void> registerCurrentToken() async {
    await _registerCurrentToken();
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await NotificationService().getToken();
      if (token != null) {
        await _register(token);
      }
    } catch (e) {
      debugPrint('[device_token_provider] Erreur register token: $e');
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

