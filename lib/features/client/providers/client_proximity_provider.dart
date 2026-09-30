import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/proximity_client_service.dart';

class ClientProximityState {
  final bool enabled;
  final bool hasPermission;
  final bool isLocationServiceEnabled;
  final bool isLoading;

  /// `true` si la permission est refusée définitivement (`deniedForever`).
  final bool isPermissionDeniedForever;

  const ClientProximityState({
    this.enabled = true,
    this.hasPermission = false,
    this.isLocationServiceEnabled = true,
    this.isLoading = false,
    this.isPermissionDeniedForever = false,
  });

  bool get isEffectivelyActive =>
      enabled && hasPermission && isLocationServiceEnabled;

  /// Le GPS du téléphone est coupé.
  bool get needsLocationService => enabled && !isLocationServiceEnabled;

  /// La permission app est refusée (mais pas forcément forever).
  bool get needsPermission =>
      enabled && isLocationServiceEnabled && !hasPermission;

  ClientProximityState copyWith({
    bool? enabled,
    bool? hasPermission,
    bool? isLocationServiceEnabled,
    bool? isLoading,
    bool? isPermissionDeniedForever,
  }) {
    return ClientProximityState(
      enabled: enabled ?? this.enabled,
      hasPermission: hasPermission ?? this.hasPermission,
      isLocationServiceEnabled:
          isLocationServiceEnabled ?? this.isLocationServiceEnabled,
      isLoading: isLoading ?? this.isLoading,
      isPermissionDeniedForever:
          isPermissionDeniedForever ?? this.isPermissionDeniedForever,
    );
  }
}

/// Observe le cycle de vie de l'app pour re-vérifier GPS + permission
/// quand l'utilisateur revient des réglages système.
class ClientProximityNotifier extends StateNotifier<ClientProximityState>
    with WidgetsBindingObserver {
  final Ref _ref;
  static const _key = 'client_proximity_enabled';

  ClientProximityNotifier(this._ref) : super(const ClientProximityState()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.enabled) {
      refreshStatus();
    }
  }

  Future<void> _init() async {
    final savedEnabled = await _readPreference();
    final permission = await Geolocator.checkPermission();
    final hasPerm = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();

    state = state.copyWith(
      enabled: savedEnabled,
      hasPermission: hasPerm,
      isLocationServiceEnabled: isServiceEnabled,
      isPermissionDeniedForever: permission == LocationPermission.deniedForever,
    );
  }

  /// Re-vérifie l'état GPS + permission après un retour des réglages système.
  Future<void> refreshStatus() async {
    final permission = await Geolocator.checkPermission();
    final hasPerm = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();

    state = state.copyWith(
      hasPermission: hasPerm,
      isLocationServiceEnabled: isServiceEnabled,
      isPermissionDeniedForever: permission == LocationPermission.deniedForever,
    );

    // Si tout est OK maintenant, déclencher un check immédiat.
    if (state.isEffectivelyActive) {
      _ref.read(proximityClientServiceProvider).checkProximity(force: true);
    }
  }

  Future<bool> _readPreference() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/settings.json');
      if (!await file.exists()) return true;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return true;
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json[_key] as bool? ?? true;
    } catch (e) {
      debugPrint('[client_proximity_provider] Erreur lecture preference: $e');
      return true;
    }
  }

  Future<void> _writePreference(bool value) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/settings.json');
      Map<String, dynamic> json = {};
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          json = jsonDecode(content) as Map<String, dynamic>;
        }
      }
      json[_key] = value;
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('[client_proximity_provider] Erreur écriture preference: $e');
    }
  }

  /// Bascule l'état d'activation et gère la demande de permission système si besoin.
  Future<bool> toggle(BuildContext context, bool targetEnabled) async {
    if (!targetEnabled) {
      state = state.copyWith(enabled: false);
      await _writePreference(false);
      return true;
    }

    state = state.copyWith(isLoading: true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          enabled: true,
          isLocationServiceEnabled: false,
          isLoading: false,
        );
        await _writePreference(true);
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          enabled: true,
          hasPermission: false,
          isPermissionDeniedForever: true,
          isLoading: false,
        );
        await _writePreference(true);
        return false;
      }

      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      state = state.copyWith(
        enabled: true,
        hasPermission: granted,
        isLocationServiceEnabled: serviceEnabled,
        isPermissionDeniedForever: false,
        isLoading: false,
      );

      await _writePreference(true);

      if (granted) {
        // Déclencher un check immédiat
        _ref.read(proximityClientServiceProvider).checkProximity(force: true);
      }

      return granted;
    } catch (e) {
      debugPrint('[client_proximity_provider] Erreur toggle proximity: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Ouvre les réglages de localisation du téléphone (GPS).
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Ouvre les réglages de l'application (permission localisation).
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final clientProximityProvider =
    StateNotifierProvider<ClientProximityNotifier, ClientProximityState>(
  (ref) => ClientProximityNotifier(ref),
);
