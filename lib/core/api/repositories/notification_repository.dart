import '../services/notification_service.dart';
import '../../../features/client/models/app_notification.dart';

class NotificationRepository {
  final NotificationService _service;

  NotificationRepository(this._service);

  Future<List<AppNotification>> list() async {
    final rows = await _service.list();
    return rows.map(AppNotification.fromApi).toList();
  }

  Future<void> markRead(String id) => _service.markRead(id);
  Future<void> markAllRead() => _service.markAllRead();
  Future<void> delete(String id) => _service.delete(id);
  Future<void> deleteAll() => _service.deleteAll();
}
