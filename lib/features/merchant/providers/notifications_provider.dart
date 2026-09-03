import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
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

    return ref.read(merchantNotificationRepositoryProvider).list();
  }

  Future<void> markRead(String id) async {
    // Mise à jour optimiste : le point bleu disparaît au tap.
    final current = state.value;
    if (current != null) {
      state = AsyncData([
        for (final n in current)
          if (n.id == id) n.copyWith(isRead: true) else n,
      ]);
    }
    try {
      await ref.read(merchantNotificationRepositoryProvider).markRead(id);
    } catch (_) {
      // Le prochain build() ré-alignera l'état.
    }
  }

  Future<void> markAllRead() async {
    // Mise à jour optimiste.
    final current = state.value;
    if (current != null) {
      state = AsyncData([for (final n in current) n.copyWith(isRead: true)]);
    }
    try {
      await ref.read(merchantNotificationRepositoryProvider).markAllRead();
    } catch (_) {
      // Le prochain build() ré-alignera l'état.
    }
  }

  Future<void> delete(String id) async {
    await ref.read(merchantNotificationRepositoryProvider).delete(id);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((n) => n.id != id).toList());
  }

  Future<void> deleteAll() async {
    await ref.read(merchantNotificationRepositoryProvider).deleteAll();
    state = const AsyncData([]);
  }
}
