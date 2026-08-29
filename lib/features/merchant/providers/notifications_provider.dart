import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
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

    return ref.read(merchantNotificationRepositoryProvider).list();
  }

  Future<void> markRead(String id) async {
    await ref.read(merchantNotificationRepositoryProvider).markRead(id);
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final n in current)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ]);
  }

  Future<void> markAllRead() async {
    await ref.read(merchantNotificationRepositoryProvider).markAllRead();
    final current = state.value;
    if (current == null) return;
    state = AsyncData([for (final n in current) n.copyWith(isRead: true)]);
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
