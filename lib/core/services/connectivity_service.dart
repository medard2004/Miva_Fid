import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus {
  online,
  offline,
}

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(ConnectivityStatus.online) {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _init() {
    // Écoute des changements d'interfaces réseau
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityResults);

    // Première vérification immédiate
    checkConnectivity();
  }

  Future<void> _handleConnectivityResults(List<ConnectivityResult> results) async {
    // Si aucun résultat ou uniquement 'none', nous sommes hors ligne immédiatement
    final hasActiveInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasActiveInterface) {
      if (mounted && state != ConnectivityStatus.offline) {
        state = ConnectivityStatus.offline;
      }
      return;
    }

    // Une interface est active (wifi, mobile...), vérifier l'accès internet réel
    await checkConnectivity();
  }

  /// Vérifie si l'accès internet réel est disponible via une requête DNS légère
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (!mounted) return false;
      final hasActiveInterface = results.any((r) => r != ConnectivityResult.none);

      if (!hasActiveInterface) {
        if (mounted && state != ConnectivityStatus.offline) {
          state = ConnectivityStatus.offline;
        }
        return false;
      }

      // Test de résolution DNS avec timeout court (3 secondes)
      final lookupResult = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (!mounted) return false;

      final isConnected = lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty;
      final newStatus = isConnected ? ConnectivityStatus.online : ConnectivityStatus.offline;

      if (mounted && state != newStatus) {
        state = newStatus;
      }
      return isConnected;
    } catch (_) {
      if (mounted && state != ConnectivityStatus.offline) {
        state = ConnectivityStatus.offline;
      }
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider fournissant le statut réseau actuel (`online` ou `offline`)
final connectivityStatusProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});

/// Provider d'aide pour savoir si l'application est hors-ligne
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStatusProvider) == ConnectivityStatus.offline;
});

/// Provider d'aide pour savoir si l'application est en ligne
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStatusProvider) == ConnectivityStatus.online;
});
