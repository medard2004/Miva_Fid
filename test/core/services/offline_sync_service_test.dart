import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miva_fid/core/cache/offline_cache_database.dart';
import 'package:miva_fid/core/services/connectivity_service.dart';
import 'package:miva_fid/core/services/offline_sync_service.dart';
import 'package:miva_fid/core/widgets/offline_banner.dart';

void main() {
  group('OfflineMutation Model', () {
    test('toMap and fromMap preserves fields and payload', () {
      final now = DateTime.now();
      final mutation = OfflineMutation(
        id: '123e4567-e89b-12d3-a456-426614174000',
        actionType: 'stamp',
        cardId: 'card-99',
        payload: {
          'amount_fcfa': 5000.0,
          'idempotency_key': '123e4567-e89b-12d3-a456-426614174000',
          'client_name': 'Koffi',
        },
        createdAt: now,
        attempts: 1,
        status: 'pending',
      );

      final map = mutation.toMap();
      final restored = OfflineMutation.fromMap(map);

      expect(restored.id, mutation.id);
      expect(restored.actionType, 'stamp');
      expect(restored.cardId, 'card-99');
      expect(restored.payload['amount_fcfa'], 5000.0);
      expect(restored.payload['idempotency_key'], mutation.id);
      expect(restored.payload['client_name'], 'Koffi');
      expect(restored.attempts, 1);
      expect(restored.status, 'pending');
    });
  });

  group('OfflineBanner Widget', () {
    testWidgets('renders orange banner when device is offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => ConnectivityNotifier()..state = ConnectivityStatus.offline,
            ),
            offlineSyncProvider.overrideWith(
              (ref) => OfflineSyncNotifierMock(
                const OfflineSyncState(
                  status: SyncStatus.idle,
                  pendingCount: 2,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mode hors ligne • 2 actions en attente'), findsOneWidget);
    });

    testWidgets('renders blue banner when syncing mutations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => ConnectivityNotifier()..state = ConnectivityStatus.online,
            ),
            offlineSyncProvider.overrideWith(
              (ref) => OfflineSyncNotifierMock(
                const OfflineSyncState(
                  status: SyncStatus.syncing,
                  pendingCount: 3,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Synchronisation en cours (3 actions restantes)...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders green banner when all mutations are synced', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => ConnectivityNotifier()..state = ConnectivityStatus.online,
            ),
            offlineSyncProvider.overrideWith(
              (ref) => OfflineSyncNotifierMock(
                const OfflineSyncState(
                  status: SyncStatus.synced,
                  pendingCount: 0,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Toutes les actions ont été synchronisées'), findsOneWidget);
    });

    testWidgets('renders empty shrink widget when online and idle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => ConnectivityNotifier()..state = ConnectivityStatus.online,
            ),
            offlineSyncProvider.overrideWith(
              (ref) => OfflineSyncNotifierMock(
                const OfflineSyncState(
                  status: SyncStatus.idle,
                  pendingCount: 0,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('empty_banner')), findsOneWidget);
    });
  });
}

class OfflineSyncNotifierMock extends StateNotifier<OfflineSyncState>
    implements OfflineSyncNotifier {
  OfflineSyncNotifierMock(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
