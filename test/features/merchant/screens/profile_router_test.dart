import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miva_fid/app.dart';
import 'package:miva_fid/core/api/core/api_client.dart';
import 'package:miva_fid/core/api/repositories/merchant_auth_repository.dart';
import 'package:miva_fid/core/api/services/merchant_auth_service.dart';
import 'package:miva_fid/core/api/storage/merchant_token_storage.dart';
import 'package:miva_fid/core/router/app_router.dart';
import 'package:miva_fid/features/client/providers/app_startup_provider.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/merchant/models/restaurant_account.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';

class _FakeTokenStorage extends MerchantTokenStorage {
  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<String?> getToken() async => 'fake';

  @override
  Future<void> deleteToken() async {}
}

void main() {
  testWidgets('Navigation réelle vers le profil marchand', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final account = const RestaurantAccount(
      id: '1',
      uuid: 'u1',
      name: 'Chez Toto',
      category: 'restauration',
      email: 'toto@test.ci',
      hasBusinessInfo: true,
      hasLocation: true,
      hasLoyaltyProgram: true,
    );

    final container = ProviderContainer(
      overrides: [
        appBrightnessProvider.overrideWithValue(Brightness.light),
        appStartupProvider.overrideWith(
          (ref) async => const AppStartupState(hasSeenOnboarding: true, lastRole: 'merchant'),
        ),
        merchantAuthProvider.overrideWith((ref) {
          final notifier = MerchantAuthNotifier(MerchantAuthRepository(
            MerchantAuthService(ApiClient(tokenStorage: _FakeTokenStorage())),
            _FakeTokenStorage(),
          ));
          notifier.setAuthenticated(account);
          return notifier;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MivaFidApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    // Après splash, on doit être sur l'écran marchand.
    expect(find.byType(MoreScreenProbe), findsNothing);
    container.read(appRouterProvider).go('/merchant/more');
    await tester.pumpAndSettle();
    expect(find.text('Profil du commerce'), findsOneWidget,
        reason: 'MoreScreen devrait être affichée');

    container.read(appRouterProvider).push('/merchant/more/profile');
    await tester.pumpAndSettle();

    expect(find.text('NOM DU COMMERCE'), findsOneWidget,
        reason: 'ProfileScreen devrait être affichée');
  });
}

class MoreScreenProbe extends StatelessWidget {
  const MoreScreenProbe({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
