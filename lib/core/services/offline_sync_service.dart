import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/core/api_exceptions.dart';
import '../api/providers/api_providers.dart';
import '../api/services/merchant_dashboard_service.dart';
import '../cache/offline_cache_database.dart';
import '../cache/offline_cache_service.dart';
import 'connectivity_service.dart';
import '../../features/merchant/providers/clients_provider.dart';
import '../../features/merchant/providers/dashboard_stats_provider.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
}

class OfflineSyncState {
  final SyncStatus status;
  final int pendingCount;
  final String? lastError;
  final DateTime? lastSyncedAt;

  const OfflineSyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastError,
    this.lastSyncedAt,
  });

  OfflineSyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    String? lastError,
    DateTime? lastSyncedAt,
  }) =>
      OfflineSyncState(
        status: status ?? this.status,
        pendingCount: pendingCount ?? this.pendingCount,
        lastError: lastError,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

class OfflineSyncNotifier extends StateNotifier<OfflineSyncState> {
  final OfflineCacheService _cache;
  final MerchantDashboardService _dashboardService;
  final Ref _ref;
  Timer? _syncedDismissTimer;

  OfflineSyncNotifier({
    required OfflineCacheService cache,
    required MerchantDashboardService dashboardService,
    required Ref ref,
  })  : _cache = cache,
        _dashboardService = dashboardService,
        _ref = ref,
        super(const OfflineSyncState()) {
    _init();
  }

  void _init() {
    refreshPendingCount();

    // Auto-sync au démarrage si en ligne et actions en attente
    Future.microtask(() async {
      await refreshPendingCount();
      if (state.pendingCount > 0 && _ref.read(isOnlineProvider)) {
        syncPending();
      }
    });

    // Écoute les transitions vers 'online' pour déclencher la synchronisation automatique
    _ref.listen<ConnectivityStatus>(connectivityStatusProvider, (previous, next) {
      if (next == ConnectivityStatus.online && previous == ConnectivityStatus.offline) {
        syncPending();
      }
    });
  }

  /// Rafraîchit le décompte des actions en attente
  Future<void> refreshPendingCount() async {
    try {
      final count = await _cache.getPendingMutationsCount();
      if (mounted) {
        state = state.copyWith(pendingCount: count);
      }
    } catch (e) {
      debugPrint('[offline_sync_service] Erreur rafraîchissement pendingCount: $e');
    }
  }

  /// Enregistre une nouvelle action hors ligne (ex: tampon accordé hors ligne)
  Future<OfflineMutation> queueStampAction({
    required String cardId,
    double? amountFcfa,
    String? clientName,
    int? currentStamps,
    int? goal,
  }) async {
    final mutationId = _generateUuid();
    final mutation = OfflineMutation(
      id: mutationId,
      actionType: 'stamp',
      cardId: cardId,
      payload: {
        if (amountFcfa != null) 'amount_fcfa': amountFcfa,
        if (clientName != null) 'client_name': clientName,
        if (currentStamps != null) 'stamps_current': currentStamps,
        if (goal != null) 'goal': goal,
        'idempotency_key': mutationId,
      },
      createdAt: DateTime.now(),
    );

    await _cache.insertMutation(mutation);

    // Mettre à jour optimiste le cache des clients locaux
    await _applyOptimisticStampUpdate(cardId, amountFcfa: amountFcfa);

    await refreshPendingCount();

    // Si on est en ligne, on tente la synchro immédiatement
    final isOnline = _ref.read(isOnlineProvider);
    if (isOnline) {
      unawaited(syncPending());
    }

    return mutation;
  }

  /// Applique le tampon localement dans `getMerchantClients()` en attendant le retour serveur
  Future<void> _applyOptimisticStampUpdate(String cardId, {double? amountFcfa}) async {
    try {
      final cached = await _cache.getMerchantClients();
      if (cached == null) return;

      final items = (cached['items'] as List?)
              ?.map((i) => Map<String, dynamic>.from(i as Map))
              .toList() ??
          [];

      for (int i = 0; i < items.length; i++) {
        if (items[i]['id']?.toString() == cardId ||
            items[i]['card_code']?.toString() == cardId) {
          final cur = (items[i]['stamps_current'] as num?)?.toInt() ?? 0;
          items[i]['stamps_current'] = cur + 1;
          items[i]['last_activity_at'] = DateTime.now().toIso8601String();
          break;
        }
      }

      cached['items'] = items;
      await _cache.saveMerchantClients(cached);
    } catch (e) {
      debugPrint('[offline_sync_service] Erreur mise à jour optimistic cache client: $e');
    }
  }

  /// Synchronise toutes les actions en attente avec le backend
  Future<void> syncPending() async {
    if (state.status == SyncStatus.syncing) return;

    final pending = await _cache.getPendingMutations();
    if (pending.isEmpty) {
      await refreshPendingCount();
      return;
    }

    state = state.copyWith(status: SyncStatus.syncing, pendingCount: pending.length);

    int successCount = 0;

    for (final mutation in pending) {
      try {
        if (mutation.actionType == 'stamp') {
          final amountFcfa = (mutation.payload['amount_fcfa'] as num?)?.toDouble();
          await _dashboardService.addStamp(
            mutation.cardId,
            amountFcfa: amountFcfa,
            idempotencyKey: mutation.id,
          );
        }

        // Action synchronisée avec succès
        await _cache.deleteMutation(mutation.id);
        successCount++;
      } catch (e) {
        if ((e is ServerException && (e.statusCode == 409 || e.statusCode == 422)) ||
            e is ValidationException) {
          // Déjà traité ou conflit métier non réessayable : supprimer pour éviter le blocage
          await _cache.deleteMutation(mutation.id);
          successCount++;
        } else if (e is NetworkException) {
          // Erreur réseau : interrompre la boucle et reprendre plus tard
          await _cache.updateMutationStatus(
            mutation.id,
            'pending',
            attempts: mutation.attempts + 1,
          );
          break;
        } else {
          // Autre erreur
          await _cache.updateMutationStatus(
            mutation.id,
            'failed',
            attempts: mutation.attempts + 1,
          );
        }
      }
    }

    final remaining = await _cache.getPendingMutationsCount();

    if (remaining == 0 && successCount > 0) {
      state = state.copyWith(
        status: SyncStatus.synced,
        pendingCount: 0,
        lastSyncedAt: DateTime.now(),
      );

      // Invalider les providers pour forcer un rafraîchissement avec les vraies données serveur
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(clientsNotifierProvider);

      // Auto-dismiss du statut 'synced' après 3 secondes
      _syncedDismissTimer?.cancel();
      _syncedDismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && state.status == SyncStatus.synced) {
          state = state.copyWith(status: SyncStatus.idle);
        }
      });
    } else {
      state = state.copyWith(
        status: remaining > 0 ? SyncStatus.error : SyncStatus.idle,
        pendingCount: remaining,
      );
    }
  }

  static String _generateUuid() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    _syncedDismissTimer?.cancel();
    super.dispose();
  }
}

final offlineSyncProvider =
    StateNotifierProvider<OfflineSyncNotifier, OfflineSyncState>((ref) {
  final cache = ref.watch(offlineCacheServiceProvider);
  final dashboardService = ref.watch(merchantDashboardServiceProvider);
  return OfflineSyncNotifier(
    cache: cache,
    dashboardService: dashboardService,
    ref: ref,
  );
});
