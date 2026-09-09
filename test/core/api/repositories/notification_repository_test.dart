import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/api/core/api_client.dart';
import 'package:miva_fid/core/api/repositories/notification_repository.dart';
import 'package:miva_fid/core/api/services/notification_service.dart';
import 'package:miva_fid/core/api/storage/token_storage.dart';

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(ApiClient apiClient) : super(apiClient);

  final List<String> markedRead = [];
  bool markedAllRead = false;
  final List<String> deleted = [];
  bool deletedAll = false;

  @override
  Future<List<Map<String, dynamic>>> list() async => [
        {
          'id': 1,
          'type': 'reward_unlocked',
          'title': 'Récompense débloquée 🎁',
          'body': 'Récompense débloquée : Café offert',
          'read_at': null,
          'created_at': '2026-08-29T10:00:00.000000Z',
        },
        {
          'id': 2,
          'type': 'referral_pending',
          'title': 'Parrainage en cours 👀',
          'body': 'Ada a rejoint grâce à votre parrainage.',
          'read_at': '2026-08-29T09:00:00.000000Z',
          'created_at': '2026-08-28T10:00:00.000000Z',
        },
      ];

  @override
  Future<void> markRead(String id) async => markedRead.add(id);

  @override
  Future<void> markAllRead() async => markedAllRead = true;

  @override
  Future<void> delete(String id) async => deleted.add(id);

  @override
  Future<void> deleteAll() async => deletedAll = true;
}

class _FakeTokenStorage implements TokenStorageBase {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'token';
  @override
  Future<void> deleteToken() async {}
}

void main() {
  group('NotificationRepository', () {
    test('list() parses API rows into AppNotification, preserving read state', () async {
      final apiClient = ApiClient(tokenStorage: _FakeTokenStorage());
      final repo = NotificationRepository(_FakeNotificationService(apiClient));

      final notifications = await repo.list();

      expect(notifications, hasLength(2));
      expect(notifications[0].id, '1');
      expect(notifications[0].type, 'reward_unlocked');
      expect(notifications[0].title, 'Récompense débloquée 🎁');
      expect(notifications[0].isRead, false);
      expect(notifications[1].isRead, true);
    });

    test('markRead/markAllRead/delete/deleteAll delegate to the service', () async {
      final apiClient = ApiClient(tokenStorage: _FakeTokenStorage());
      final service = _FakeNotificationService(apiClient);
      final repo = NotificationRepository(service);

      await repo.markRead('1');
      await repo.markAllRead();
      await repo.delete('2');
      await repo.deleteAll();

      expect(service.markedRead, ['1']);
      expect(service.markedAllRead, true);
      expect(service.deleted, ['2']);
      expect(service.deletedAll, true);
    });
  });
}
