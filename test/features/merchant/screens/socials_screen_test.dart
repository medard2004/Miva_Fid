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
import 'package:miva_fid/features/merchant/screens/socials_screen.dart';
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
}

void main() {
  testWidgets('SocialsScreen displays available platforms, adds and updates live client preview',
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
                  whatsapp: '',
                  instagram: '',
                  facebook: '',
                  tiktok: '',
                  loyaltyConfig: {},
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
          home: const SocialsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Section Headers
    expect(find.text('Réseaux sociaux & Contact'), findsOneWidget);
    expect(find.text('Aperçu rendu côté client'), findsOneWidget);
    expect(find.text('Réseaux disponibles à ajouter'), findsOneWidget);

    // Initial empty state
    expect(find.text('Aucun réseau social configuré'), findsOneWidget);

    // Available platforms to add
    expect(find.text('WhatsApp'), findsWidgets);
    expect(find.text('Instagram'), findsWidgets);
    expect(find.text('Facebook'), findsWidgets);
    expect(find.text('TikTok'), findsWidgets);
    expect(find.text('Avis Google'), findsNothing);

    // Tap to add Instagram
    final instagramBtn = find.ancestor(
      of: find.text('Instagram'),
      matching: find.byType(InkWell),
    );
    expect(instagramBtn, findsOneWidget);
    await tester.tap(instagramBtn);
    await tester.pumpAndSettle();

    // Verify Instagram card is now added in configured section
    expect(find.text('Position #1'), findsOneWidget);

    // 1 clean TextField in configured platform card for handle/pseudo
    final textFields = find.byType(TextField);
    expect(textFields, findsOneWidget);

    // Enter handle/pseudo 'botega_store'
    await tester.enterText(textFields.first, 'botega_store');
    await tester.pumpAndSettle();

    // Live client preview displays 'botega_store' (1 in TextField, 1 in live preview)
    expect(find.text('botega_store'), findsNWidgets(2));

    // Tap to add WhatsApp
    final whatsappBtn = find.ancestor(
      of: find.text('WhatsApp'),
      matching: find.byType(InkWell),
    );
    expect(whatsappBtn, findsOneWidget);
    await tester.ensureVisible(whatsappBtn);
    await tester.pumpAndSettle();
    await tester.tap(whatsappBtn);
    await tester.pumpAndSettle();

    expect(find.text('Position #2'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Reorder: Move WhatsApp up
    final upButtons = find.byTooltip('Monter');
    expect(upButtons, findsNWidgets(2));
    await tester.ensureVisible(upButtons.at(1));
    await tester.pumpAndSettle();
    await tester.tap(upButtons.at(1));
    await tester.pumpAndSettle();

    // Verify remove button
    final removeButtons = find.byTooltip('Retirer');
    expect(removeButtons, findsNWidgets(2));
    await tester.ensureVisible(removeButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle();

    // One platform remaining with 1 TextField
    expect(find.byType(TextField), findsOneWidget);
  });
}
