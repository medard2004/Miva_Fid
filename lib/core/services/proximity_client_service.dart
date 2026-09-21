import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../api/providers/api_providers.dart';
import '../../features/client/providers/app_providers.dart';
import '../../features/client/providers/client_proximity_provider.dart';

/// Service client léger et économique en batterie pour la détection de proximité.
///
/// Déclenche la vérification géographique côté serveur (`/client/location/proximity-check`) :
/// - À la reprise de l'application (`AppLifecycleState.resumed`).
/// - Périodiquement toutes les 2 minutes pendant que l'application est active.
/// - Uniquement si l'utilisateur client est connecté et a accordé l'accès à la localisation.
/// - Avec un filtre de déplacement (> 30 m) et un étranglement temporel (minimum 60 s).
class ProximityClientService with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _periodicTimer;
  DateTime? _lastCheckTime;
  Position? _lastPosition;
  bool _isChecking = false;

  static const Duration _checkInterval = Duration(minutes: 2);
  static const Duration _minIntervalBetweenChecks = Duration(seconds: 60);
  static const double _minDistanceMovedMeters = 30.0;

  ProximityClientService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  void _init() {
    _startPeriodicTimer();
    // Délai initial léger après démarrage complet de l'application
    Future.delayed(const Duration(seconds: 3), () {
      checkProximity();
    });
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_checkInterval, (_) {
      checkProximity();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkProximity();
    }
  }

  /// Exécute une vérification de proximité auprès du serveur si les conditions sont remplies.
  Future<void> checkProximity({bool force = false}) async {
    if (_isChecking) return;

    // 1. Uniquement pour un utilisateur client authentifié
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      return;
    }

    // 2. Vérifier si l'utilisateur a activé les alertes de proximité dans ses paramètres
    final proximityState = _ref.read(clientProximityProvider);
    if (!proximityState.enabled) {
      return;
    }

    // 2. Étranglement temporel pour préserver la batterie et le réseau
    final now = DateTime.now();
    if (!force && _lastCheckTime != null) {
      if (now.difference(_lastCheckTime!) < _minIntervalBetweenChecks) {
        return;
      }
    }

    try {
      _isChecking = true;

      // 3. Vérifier si le service de localisation OS est activé
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return;
      }

      // 4. Vérifier les permissions sans boîte de dialogue intrusive en arrière-plan
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      // 5. Récupérer la position avec précision moyenne (économique en énergie)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 6. Si l'utilisateur n'a quasiment pas bougé (< 30 m), pas besoin d'appeler l'API
      if (!force && _lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < _minDistanceMovedMeters) {
          _lastCheckTime = now;
          return;
        }
      }

      _lastPosition = position;
      _lastCheckTime = now;

      // 7. Appel vers le backend Laravel
      final client = _ref.read(apiClientProvider);
      final response = await client.dio.post(
        '/client/location/proximity-check',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      if (kDebugMode) {
        debugPrint('[ProximityClientService] Proximity checked: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProximityClientService] Check error: $e');
      }
    } finally {
      _isChecking = false;
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

final proximityClientServiceProvider = Provider<ProximityClientService>((ref) {
  final service = ProximityClientService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
