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
import 'package:miva_fid/features/onboarding/widgets/loyalty_card_preview.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/models/merchant_model.dart';
import 'package:miva_fid/features/merchant/models/restaurant_account.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';
import 'package:miva_fid/features/merchant/providers/merchant_provider.dart';
import 'package:miva_fid/features/merchant/screens/programme_design_screen.dart';

class _FakeMerchantNotifier extends MerchantNotifier {
  Map<String, dynamic>? lastUpdatedPayload;

  @override
  Future<MerchantModel?> build() async => MerchantModel(
        id: '1',
        userId: 'u1',
        name: 'Papiro',
        category: 'Salon de beauté',
        colorPrimary: '#DB2777',
        colorSecondary: '#9C1A54',
        stampDesignType: 'icon',
        stampEmoji: '✨',
        stampIcon: 'local_cafe_rounded',
        cardDecorationPattern: 'dots',
        cardGradientType: 'linear',
        loyaltyMode: 'stamps',
        stampsRequired: 10,
        createdAt: DateTime(2025),
      );

  @override
  Future<void> updateProgramme(Map<String, dynamic> data) async {
    lastUpdatedPayload = data;
  }
}

class _FakeTokenStorage extends MerchantTokenStorage {
  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<String?> getToken() async => 'fake';

  @override
  Future<void> deleteToken() async {}
}

void main() {
  Widget buildTestWidget({required _FakeMerchantNotifier notifier}) {
    final fakeAuthRepo = MerchantAuthRepository(
      MerchantAuthService(ApiClient(tokenStorage: _FakeTokenStorage())),
      _FakeTokenStorage(),
    );

    return ProviderScope(
      overrides: [
        appBrightnessProvider.overrideWithValue(Brightness.light),
        merchantNotifierProvider.overrideWith(() => notifier),
        merchantAuthProvider.overrideWith((ref) {
          final authNotifier = MerchantAuthNotifier(fakeAuthRepo);
          authNotifier.state = authNotifier.state.copyWith(
            restaurant: const RestaurantAccount(
              id: '1',
              uuid: 'uuid-1',
              email: 'papiro@example.com',
              name: 'Papiro',
              category: 'Salon de beauté',
              loyaltyType: 'stamps',
              loyaltyConfig: {
                'color_primary': '#DB2777',
                'color_secondary': '#9C1A54',
                'stamp_design_type': 'icon',
                'stamp_emoji': '✨',
                'stamp_icon': 'local_cafe_rounded',
                'card_decoration_pattern': 'dots',
                'card_gradient_type': 'linear',
              },
            ),
          );
          return authNotifier;
        }),
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
        home: const ProgrammeDesignScreen(),
      ),
    );
  }

  testWidgets('ProgrammeDesignScreen rend tous ses composants sans aucune exception de layout', (tester) async {
    final fakeNotifier = _FakeMerchantNotifier();

    await tester.pumpWidget(buildTestWidget(notifier: fakeNotifier));
    await tester.pump();
    await tester.pumpAndSettle();

    // Vérification qu'aucune exception n'a été interceptée
    expect(tester.takeException(), isNull);

    // Vérification que tous les éléments essentiels sont présents et visibles
    expect(find.byType(LoyaltyCardPreview), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('Logo du commerce'), findsOneWidget);
    expect(find.text('Couleur principale'), findsOneWidget);
    expect(find.text('Motif de fond'), findsOneWidget);
    expect(find.text('Style des tampons'), findsOneWidget);
    expect(find.text('Enregistrer le design'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('ProgrammeDesignScreen permet de changer de motif de fond et d\'enregistrer', (tester) async {
    final fakeNotifier = _FakeMerchantNotifier();

    await tester.pumpWidget(buildTestWidget(notifier: fakeNotifier));
    await tester.pump();
    await tester.pumpAndSettle();

    // Scroll vers le bouton 'Traits' (off-screen dans le viewport 600px)
    final traitsBtn = find.text('Traits');
    await tester.ensureVisible(traitsBtn);
    await tester.pumpAndSettle();
    expect(traitsBtn, findsOneWidget);
    await tester.tap(traitsBtn);
    await tester.pumpAndSettle();

    // Scroll vers 'Enregistrer le design' puis cliquer
    final saveBtn = find.text('Enregistrer le design');
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pump();
    await tester.pumpAndSettle();

    // Vérifier que le payload a bien été mis à jour avec le motif 'lines'
    expect(fakeNotifier.lastUpdatedPayload, isNotNull);
    expect(fakeNotifier.lastUpdatedPayload!['card_decoration_pattern'], 'lines');
  });

  testWidgets('ProgrammeDesignScreen permet de basculer vers les émojis', (tester) async {
    final fakeNotifier = _FakeMerchantNotifier();

    await tester.pumpWidget(buildTestWidget(notifier: fakeNotifier));
    await tester.pump();
    await tester.pumpAndSettle();

    // Scroll vers le bouton Emoji (off-screen)
    final emojiBtn = find.text('Emoji');
    await tester.ensureVisible(emojiBtn);
    await tester.pumpAndSettle();
    expect(emojiBtn, findsOneWidget);
    await tester.tap(emojiBtn);
    await tester.pumpAndSettle();

    // Le bottom sheet de sélection d'emoji s'ouvre
    expect(find.text('Choisir un emoji'), findsOneWidget);

    // Sélectionner un émoji (par exemple ❤️)
    final heartEmoji = find.text('❤️');
    expect(heartEmoji, findsWidgets);
    await tester.tap(heartEmoji.first);
    await tester.pumpAndSettle();

    // Scroll vers Sauvegarder
    final saveBtn = find.text('Enregistrer le design');
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(fakeNotifier.lastUpdatedPayload, isNotNull);
    expect(fakeNotifier.lastUpdatedPayload!['stamp_design_type'], 'emoji');
    expect(fakeNotifier.lastUpdatedPayload!['stamp_emoji'], '❤️');
  });
}
