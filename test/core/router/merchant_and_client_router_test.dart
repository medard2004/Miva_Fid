import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:miva_fid/core/router/client_router.dart';
import 'package:miva_fid/core/router/merchant_router.dart';
import 'package:miva_fid/features/client/models/user.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/merchant/models/restaurant_account.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

bool _hasRoutePrefix(List<RouteBase> routes, String prefix) {
  for (final r in routes) {
    if (r is GoRoute && r.path.startsWith(prefix)) return true;
    if (r is ShellRoute && _hasRoutePrefix(r.routes, prefix)) return true;
    if (r is StatefulShellRoute) {
      for (final branch in r.branches) {
        if (_hasRoutePrefix(branch.routes, prefix)) return true;
      }
    }
  }
  return false;
}

Widget _wrapWithScope(ProviderContainer container, GoRouter router) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('MerchantRouter Tests', () {
    test('merchantRouterProvider initialisation et configuration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(merchantRouterProvider);
      expect(router, isNotNull);
      expect(router.configuration.routes.isNotEmpty, isTrue);
    });

    test('initialLocation est bien /merchant', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(merchantRouterProvider);
      expect(router.routeInformationProvider.value.uri.path, '/merchant');
    });

    testWidgets('redirection non-authentifié renvoie vers /auth/merchant/auth', (tester) async {
      final container = ProviderContainer(
        overrides: [
          merchantAuthProvider.overrideWith((ref) => _FakeMerchantAuthNotifier(
                const MerchantAuthState(isAuthenticated: false),
              )),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(merchantRouterProvider);
      await tester.pumpWidget(_wrapWithScope(container, router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/auth/merchant/auth');
    });

    testWidgets('accès aux routes légales marchandes sans authentification', (tester) async {
      final container = ProviderContainer(
        overrides: [
          merchantAuthProvider.overrideWith((ref) => _FakeMerchantAuthNotifier(
                const MerchantAuthState(isAuthenticated: false),
              )),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(merchantRouterProvider);
      await tester.pumpWidget(_wrapWithScope(container, router));
      await tester.pumpAndSettle();

      router.go('/merchant/legal/terms');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/merchant/legal/terms');

      router.go('/merchant/legal/privacy');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/merchant/legal/privacy');
    });

    testWidgets('redirection authentifié avec programme va vers /merchant', (tester) async {
      const restaurant = RestaurantAccount(
        id: '1',
        uuid: 'uuid-1',
        email: 'resto@test.com',
        name: 'Resto Test',
        hasBusinessInfo: true,
        hasLocation: true,
        hasLoyaltyProgram: true,
      );

      final container = ProviderContainer(
        overrides: [
          merchantAuthProvider.overrideWith((ref) => _FakeMerchantAuthNotifier(
                const MerchantAuthState(
                  isAuthenticated: true,
                  restaurant: restaurant,
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(merchantRouterProvider);
      await tester.pumpWidget(_wrapWithScope(container, router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/merchant');
    });

    test('isolation: absence de routes client dans merchantRouterProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(merchantRouterProvider);
      expect(_hasRoutePrefix(router.configuration.routes, '/client/wallet'), isFalse);
    });
  });

  group('ClientRouter Tests', () {
    test('clientRouterProvider initialisation et configuration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(clientRouterProvider);
      expect(router, isNotNull);
      expect(router.configuration.routes.isNotEmpty, isTrue);
    });

    test('initialLocation est bien /client/wallet', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(clientRouterProvider);
      expect(router.routeInformationProvider.value.uri.path, '/client/wallet');
    });

    testWidgets('redirection non-authentifié sur /client/wallet renvoie vers /client/auth', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeClientAuthNotifier(
                const AuthState(isAuthenticated: false),
              )),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(clientRouterProvider);
      await tester.pumpWidget(_wrapWithScope(container, router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/client/auth');
    });

    testWidgets('deep linking: /join?code=RESTO123 redirige vers /client/onboarding/join avec code préservé', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeClientAuthNotifier(
                const AuthState(isAuthenticated: false),
              )),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(clientRouterProvider);
      await tester.pumpWidget(_wrapWithScope(container, router));
      await tester.pumpAndSettle();

      router.go('/join?code=RESTO123');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final currentUri = router.routeInformationProvider.value.uri;
      expect(currentUri.path, '/client/onboarding/join');
      expect(currentUri.queryParameters['code'], 'RESTO123');
    });

    testWidgets('deep linking: accès direct /client/onboarding/join?code=RESTO123 et rechargement', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeClientAuthNotifier(
                const AuthState(isAuthenticated: false),
              )),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(clientRouterProvider);
      await tester.pumpWidget(_wrapWithScope(container, router));
      await tester.pumpAndSettle();

      // Accès direct
      router.go('/client/onboarding/join?code=RESTO123');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      var currentUri = router.routeInformationProvider.value.uri;
      expect(currentUri.path, '/client/onboarding/join');
      expect(currentUri.queryParameters['code'], 'RESTO123');

      // Simulation de rechargement direct de l'URL
      router.go('/client/onboarding/join?code=RESTO123');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      currentUri = router.routeInformationProvider.value.uri;
      expect(currentUri.path, '/client/onboarding/join');
      expect(currentUri.queryParameters['code'], 'RESTO123');
    });

    testWidgets('redirection authentifié client autorise le wallet', (tester) async {
      final user = AppUser(
        id: 'u-1',
        phoneNumber: '+22890000000',
        fullName: 'Afi Koko',
        joinDate: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeClientAuthNotifier(
                AuthState(isAuthenticated: true, user: user),
              )),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(clientRouterProvider);
      await tester.pumpWidget(_wrapWithScope(container, router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/client/wallet');
    });

    test('isolation: absence de routes marchandes dans clientRouterProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(clientRouterProvider);
      expect(_hasRoutePrefix(router.configuration.routes, '/merchant'), isFalse);
    });
  });
}

class _FakeMerchantAuthNotifier extends StateNotifier<MerchantAuthState>
    implements MerchantAuthNotifier {
  _FakeMerchantAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClientAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeClientAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
