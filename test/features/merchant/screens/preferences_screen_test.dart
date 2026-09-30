import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miva_fid/core/api/core/api_client.dart';
import 'package:miva_fid/core/api/repositories/merchant_auth_repository.dart';
import 'package:miva_fid/core/api/services/merchant_auth_service.dart';
import 'package:miva_fid/core/api/storage/merchant_token_storage.dart';
import 'package:miva_fid/core/theme/app_theme.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/merchant/models/restaurant_account.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';
import 'package:miva_fid/features/merchant/screens/preferences_screen.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

class _FakeTokenStorage extends MerchantTokenStorage {
  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<String?> getToken() async => 'fake';

  @override
  Future<void> deleteToken() async {}
}

class _TestMerchantAuthRepository extends MerchantAuthRepository {
  _TestMerchantAuthRepository()
      : super(
          MerchantAuthService(ApiClient(tokenStorage: _FakeTokenStorage())),
          _FakeTokenStorage(),
        );

  Map<String, bool>? lastUpdatedPreferences;

  @override
  Future<RestaurantAccount> updateNotificationPreferences(
      Map<String, bool> patch) async {
    lastUpdatedPreferences = patch;
    return RestaurantAccount(
      id: '1',
      uuid: 'uuid-1',
      name: 'Chez Awa',
      category: 'Restaurant',
      email: 'awa@example.com',
      hasBusinessInfo: true,
      hasLocation: true,
      hasLoyaltyProgram: true,
      notificationPreferences: patch,
    );
  }
}

void main() {
  testWidgets('PreferencesScreen displays functional notification preference switches',
      (tester) async {
    final repo = _TestMerchantAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBrightnessProvider.overrideWithValue(Brightness.light),
          merchantAuthProvider.overrideWith(
            (ref) {
              final notifier = MerchantAuthNotifier(repo);
              notifier.state = const MerchantAuthState(
                restaurant: RestaurantAccount(
                  id: '1',
                  uuid: 'uuid-1',
                  name: 'Chez Awa',
                  category: 'Restaurant',
                  email: 'awa@example.com',
                  hasBusinessInfo: true,
                  hasLocation: true,
                  hasLoyaltyProgram: true,
                  notificationPreferences: {
                    'new_client': true,
                    'reward': true,
                    'low_sms': true,
                  },
                ),
              );
              return notifier;
            },
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PreferencesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alertes & Notifications en direct'), findsOneWidget);
    expect(find.text('Nouveau client'), findsOneWidget);
    expect(find.text('Récompense gagnée'), findsOneWidget);
    expect(find.text('Quota SMS faible'), findsOneWidget);

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(3));

    // Toggle first switch (new_client)
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    expect(repo.lastUpdatedPreferences, {'new_client': false});
  });
}
