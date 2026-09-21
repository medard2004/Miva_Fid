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

  const ClientProximityState({
    this.enabled = true,
    this.hasPermission = false,
    this.isLocationServiceEnabled = true,
    this.isLoading = false,
  });

  bool get isEffectivelyActive =>
      enabled && hasPermission && isLocationServiceEnabled;

  ClientProximityState copyWith({
    bool? enabled,
    bool? hasPermission,
    bool? isLocationServiceEnabled,
    bool? isLoading,
  }) {
    return ClientProximityState(
      enabled: enabled ?? this.enabled,
      hasPermission: hasPermission ?? this.hasPermission,
      isLocationServiceEnabled:
          isLocationServiceEnabled ?? this.isLocationServiceEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ClientProximityNotifier extends StateNotifier<ClientProximityState> {
  final Ref _ref;
  static const _key = 'client_proximity_enabled';

  ClientProximityNotifier(this._ref) : super(const ClientProximityState()) {
    _init();
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
    );
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
    } catch (_) {
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
    } catch (_) {}
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
          isLocationServiceEnabled: false,
          isLoading: false,
        );
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          hasPermission: false,
          isLoading: false,
        );
        await Geolocator.openAppSettings();
        return false;
      }

      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      state = state.copyWith(
        enabled: granted,
        hasPermission: granted,
        isLocationServiceEnabled: serviceEnabled,
        isLoading: false,
      );

      await _writePreference(granted);

      if (granted) {
        // Déclencher un check immédiat
        _ref.read(proximityClientServiceProvider).checkProximity(force: true);
      }

      return granted;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Ouvre les réglages de l'application si l'utilisateur a refusé définitivement la permission.
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}

final clientProximityProvider =
    StateNotifierProvider<ClientProximityNotifier, ClientProximityState>(
  (ref) => ClientProximityNotifier(ref),
);
