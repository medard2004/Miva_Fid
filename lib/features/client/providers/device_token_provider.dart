import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
/// ── Ré-enregistrement périodique (fiabilité push) ────────────────
/// Sur le Web/PWA mobile, les tokens FCM peuvent devenir invalides
/// quand le navigateur est mis à jour, les données du site sont
/// effacées, ou le SW est ré-enregistré après inactivité. Pour éviter
/// les notifications perdues, le token est ré-enregistré :
///   • à chaque retour dans l'app (visibilitychange / AppLifecycle)
///   • toutes les 30 minutes tant que l'app est active
///
/// Côté marchand, cela garantit que le token FCM est ré-enregistré
/// lorsqu'un établissement est réactivé dans Filament et que le marchand
/// actualise son écran (pull-to-refresh → `refreshFromApi()` → state change
/// → listener ici).
class DeviceTokenNotifier extends WidgetsBindingObserver {
  DeviceTokenNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, _onAuthChanged, fireImmediately: true);
    _ref.listen<MerchantAuthState>(merchantAuthProvider, _onMerchantAuthChanged,
        fireImmediately: true);
    _refreshSub = NotificationService().onTokenRefresh.listen(_onTokenRefreshed);

    // Ré-enregistrement périodique toutes les 30 minutes
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _reRegisterIfAuthenticated(),
    );

    // Écouter les changements de cycle de vie (retour au premier plan)
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref _ref;
  StreamSubscription<String>? _refreshSub;
  Timer? _periodicTimer;

  /// Évite les ré-enregistrements trop fréquents (debounce 60s).
  DateTime? _lastRegistrationAt;
  static const _minRegistrationInterval = Duration(seconds: 60);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quand l'app revient au premier plan (mobile natif + web tab visible),
    // on ré-enregistre le token pour s'assurer qu'il est toujours valide.
    if (state == AppLifecycleState.resumed) {
      _reRegisterIfAuthenticated();
    }
  }

  void _onAuthChanged(AuthState? previous, AuthState next) {
    if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
      _registerCurrentToken(forMerchant: false);
    }
  }

  void _onMerchantAuthChanged(
      MerchantAuthState? previous, MerchantAuthState next) {
    if (next.isAuthenticated &&
        (previous == null || !previous.isAuthenticated)) {
      _registerCurrentToken(forMerchant: true);
    }
  }

  void _onTokenRefreshed(String token) {
    final isClientAuth = _ref.read(authProvider).isAuthenticated;
    final isMerchantAuth = _ref.read(merchantAuthProvider).isAuthenticated;
    if (isClientAuth) {
      _register(token, forMerchant: false).catchError((e) {
        debugPrint('[device_token_provider] Erreur refresh token client: $e');
        return false;
      });
    }
    if (isMerchantAuth) {
      _register(token, forMerchant: true).catchError((e) {
        debugPrint('[device_token_provider] Erreur refresh token marchand: $e');
        return false;
      });
    }
  }

  /// Ré-enregistre le token FCM actuel — appelé au login et exposé
  /// publiquement pour le pull-to-refresh marchand après une réactivation.
  Future<bool> registerCurrentToken() async {
    final isMerchantAuth = _ref.read(merchantAuthProvider).isAuthenticated;
    final isClientAuth = _ref.read(authProvider).isAuthenticated;
    if (!isMerchantAuth && !isClientAuth) return false;

    bool ok = false;
    if (isClientAuth) {
      ok = await _registerCurrentToken(forMerchant: false) || ok;
    }
    if (isMerchantAuth) {
      ok = await _registerCurrentToken(forMerchant: true) || ok;
    }
    return ok;
  }

  /// Ré-enregistre le token si l'utilisateur est authentifié et si
  /// le dernier enregistrement date de plus de [_minRegistrationInterval].
  void _reRegisterIfAuthenticated() {
    final now = DateTime.now();
    if (_lastRegistrationAt != null &&
        now.difference(_lastRegistrationAt!) < _minRegistrationInterval) {
      return; // Trop tôt, on skip pour ne pas surcharger l'API
    }

    final isClientAuth = _ref.read(authProvider).isAuthenticated;
    final isMerchantAuth = _ref.read(merchantAuthProvider).isAuthenticated;
    if (!isClientAuth && !isMerchantAuth) return;

    _lastRegistrationAt = now;

    if (isClientAuth) {
      _registerCurrentToken(forMerchant: false).catchError((e) {
        debugPrint('[device_token_provider] Erreur re-register client: $e');
        return false;
      });
    }
    if (isMerchantAuth) {
      _registerCurrentToken(forMerchant: true).catchError((e) {
        debugPrint('[device_token_provider] Erreur re-register marchand: $e');
        return false;
      });
    }
  }

  Future<bool> _registerCurrentToken({required bool forMerchant}) async {
    try {
      final token = await NotificationService().getToken();
      if (token != null && token.isNotEmpty) {
        return await _register(token, forMerchant: forMerchant);
      }
      debugPrint('[device_token_provider] Aucun token FCM obtenu (vapidKey ou permission manquante)');
      return false;
    } catch (e) {
      debugPrint('[device_token_provider] Erreur register token: $e');
      return false;
    }
  }

  Future<bool> _register(String token, {required bool forMerchant}) {
    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    final service = forMerchant
        ? _ref.read(merchantDeviceTokenServiceProvider)
        : _ref.read(deviceTokenServiceProvider);
    return service.register(token, platform);
  }

  void dispose() {
    _refreshSub?.cancel();
    _periodicTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

final deviceTokenProvider = Provider<DeviceTokenNotifier>((ref) {
  final notifier = DeviceTokenNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

