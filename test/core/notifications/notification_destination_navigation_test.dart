import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:miva_fid/core/notifications/notification_destination.dart';

/// Miroir de la topologie réelle (`ShellRoute` pour les onglets client,
/// `/client/notifications` hors coquille) — c'est ce `push` d'onglet qui
/// déclenche l'assertion GoRouter au clic sur une notif récompense.
GoRouter _router({String initialLocation = '/client/wallet'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: child,
          bottomNavigationBar: const SizedBox(height: 8),
        ),
        routes: [
          GoRoute(
            path: '/client/wallet',
            builder: (_, __) => const Text('wallet'),
          ),
          GoRoute(
            path: '/client/rewards',
            builder: (_, state) => Text(
              'rewards:${state.uri.queryParameters['openReward'] ?? ''}',
            ),
          ),
          GoRoute(
            path: '/client/referral',
            builder: (_, __) => const Text('referral'),
          ),
        ],
      ),
      GoRoute(
        path: '/client/notifications',
        builder: (context, _) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => navigateToNotificationDestination(
                  context,
                  const RewardDestination('42'),
                ),
                child: const Text('open-reward-notif'),
              ),
              TextButton(
                onPressed: () => navigateToNotificationDestination(
                  context,
                  const ReferralDestination(),
                ),
                child: const Text('open-referral-notif'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/client/card/:id',
        builder: (_, state) => Text('card:${state.pathParameters['id']}'),
      ),
    ],
  );
}

void main() {
  Future<void> _openInbox(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/client/notifications');
    await tester.pumpAndSettle();
  }

  testWidgets(
    'clic notif récompense depuis la boîte (ouverte depuis un onglet) ouvre l\'onglet sans assertion',
    (tester) async {
      FlutterError.onError =
          (details) => fail('${details.exceptionAsString()}\n${details.stack}');

      final router = _router();
      await _openInbox(tester, router);

      await tester.tap(find.text('open-reward-notif'));
      await tester.pumpAndSettle();

      expect(find.text('rewards:42'), findsOneWidget);
    },
  );

  testWidgets(
    'clic notif parrainage depuis la boîte (ouverte depuis un onglet) ouvre l\'onglet sans assertion',
    (tester) async {
      FlutterError.onError =
          (details) => fail('${details.exceptionAsString()}\n${details.stack}');

      final router = _router();
      await _openInbox(tester, router);

      await tester.tap(find.text('open-referral-notif'));
      await tester.pumpAndSettle();

      expect(find.text('referral'), findsOneWidget);
    },
  );

  testWidgets(
    'clic notif carte (hors coquille) continue d\'empiler la fiche',
    (tester) async {
      final router = _router();
      await _openInbox(tester, router);

      final context = tester.element(find.text('open-reward-notif'));
      navigateToNotificationDestination(context, const CardDestination('7'));
      await tester.pumpAndSettle();

      expect(find.text('card:7'), findsOneWidget);
    },
  );
}
