import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../core/cache/offline_cache_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../client/models/app_notification.dart';
import 'merchant_auth_provider.dart';

part 'notifications_provider.g.dart';

/// Centre de notifications marchand (`/merchant/notifications`).
@riverpod
class MerchantNotificationsNotifier extends _$MerchantNotificationsNotifier {
  @override
  Future<List<AppNotification>> build() async {
    final restaurant = ref.watch(
      merchantAuthProvider.select((s) => s.restaurant),
    );
    if (restaurant == null) return [];

    // Recharge la liste dès qu'une notification est créée côté serveur
    // (`NotificationCreated`, canal `merchant.{id}`) — la cloche/l'inbox
    // marchande n'attendent plus le prochain chargement manuel de l'écran.
    final sub = RealtimeService.instance.onNotificationCreated.listen((_) {
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    final cache = ref.watch(offlineCacheServiceProvider);
    try {
      final items = await ref.read(merchantNotificationRepositoryProvider).list();
      await cache.saveMerchantNotifications(items.map((n) => n.toJson()).toList());
      return items;
    } catch (e) {
      final cached = await cache.getMerchantNotifications();
      if (cached != null) {
        return cached.map(AppNotification.fromApi).toList();
      }
      rethrow;
    }
  }

  Future<void> markRead(String id) async {
    // Mise à jour optimiste : le point bleu disparaît au tap.
    final current = state.value;
    if (current != null) {
      final updated = [
        for (final n in current)
          if (n.id == id) n.copyWith(isRead: true) else n,
      ];
      state = AsyncData(updated);
      unawaited(ref.read(offlineCacheServiceProvider).saveMerchantNotifications(
        updated.map((n) => n.toJson()).toList(),
      ));
    }
    try {
      await ref.read(merchantNotificationRepositoryProvider).markRead(id);
    } catch (e) {
      debugPrint('[notifications_provider] Erreur markRead marchand: $e');
      // Le prochain build() ré-alignera l'état si en ligne.
    }
  }

  Future<void> markAllRead() async {
    // Mise à jour optimiste.
    final current = state.value;
    if (current != null) {
      final updated = [for (final n in current) n.copyWith(isRead: true)];
      state = AsyncData(updated);
      unawaited(ref.read(offlineCacheServiceProvider).saveMerchantNotifications(
        updated.map((n) => n.toJson()).toList(),
      ));
    }
    try {
      await ref.read(merchantNotificationRepositoryProvider).markAllRead();
    } catch (e) {
      debugPrint('[notifications_provider] Erreur markAllRead marchand: $e');
      // Le prochain build() ré-alignera l'état si en ligne.
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(merchantNotificationRepositoryProvider).delete(id);
    } catch (e) {
      debugPrint('[notifications_provider] Erreur delete marchand: $e');
    }
    final current = state.value;
    if (current == null) return;
    final updated = current.where((n) => n.id != id).toList();
    state = AsyncData(updated);
    unawaited(ref.read(offlineCacheServiceProvider).saveMerchantNotifications(
      updated.map((n) => n.toJson()).toList(),
    ));
  }

  Future<void> deleteAll() async {
    try {
      await ref.read(merchantNotificationRepositoryProvider).deleteAll();
    } catch (e) {
      debugPrint('[notifications_provider] Erreur deleteAll marchand: $e');
    }
    state = const AsyncData([]);
    unawaited(ref.read(offlineCacheServiceProvider).saveMerchantNotifications([]));
  }
}
