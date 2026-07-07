import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'offline_sync_service.g.dart';

@Riverpod(keepAlive: true)
OfflineSyncService offlineSyncService(OfflineSyncServiceRef ref) {
  return OfflineSyncService();
}

class OfflineSyncService {
  OfflineSyncService() {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) =>
          r == ConnectivityResult.mobile || r == ConnectivityResult.wifi);
      if (connected) _flushQueue();
    });
  }

  /// Add a stamp to the offline queue when there's no connectivity
  Future<void> queueStamp(Map<String, dynamic> stampData) async {
    final box = Hive.box('stamps_queue');
    await box.add(stampData);
  }

  /// Flush all queued stamps to Supabase
  Future<void> _flushQueue() async {
    final box = Hive.box('stamps_queue');
    if (box.isEmpty) return;

    final queue = box.values.toList();
    int synced = 0;

    for (final stamp in queue) {
      try {
        await Supabase.instance.client
            .from('stamps')
            .insert(Map<String, dynamic>.from(stamp as Map));
        synced++;
      } catch (_) {
        // Keep failed stamps in queue for next attempt
      }
    }

    if (synced > 0) {
      await box.clear();
      debugPrint('[OfflineSync] $synced tampon(s) synchronisé(s)');
    }
  }

  /// Cache a loyalty card locally
  Future<void> cacheCard(String merchantId, Map<String, dynamic> data) async {
    final box = Hive.box('cards_cache');
    await box.put(merchantId, data);
  }

  /// Get a cached card
  Map<String, dynamic>? getCachedCard(String merchantId) {
    final box = Hive.box('cards_cache');
    final data = box.get(merchantId);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  /// Cache merchant data
  Future<void> cacheMerchant(Map<String, dynamic> data) async {
    final box = Hive.box('merchant_cache');
    await box.put('merchant', data);
  }

  /// Get cached merchant
  Map<String, dynamic>? getCachedMerchant() {
    final box = Hive.box('merchant_cache');
    final data = box.get('merchant');
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }
}
