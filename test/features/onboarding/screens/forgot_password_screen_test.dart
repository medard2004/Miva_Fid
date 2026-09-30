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
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';
import 'package:miva_fid/features/onboarding/screens/forgot_password_screen.dart';
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

  String? sentIdentifier;

  @override
  Future<String> forgotPassword(String identifier) async {
    sentIdentifier = identifier;
    return 'Code envoyé';
  }
}

void main() {
  testWidgets('ForgotPasswordScreen toggles between phone and email and sends code',
      (tester) async {
    final repo = _TestMerchantAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBrightnessProvider.overrideWithValue(Brightness.light),
          merchantAuthProvider.overrideWith(
            (ref) => MerchantAuthNotifier(repo),
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
          home: const ForgotPasswordScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('NUMÉRO DE TÉLÉPHONE'), findsOneWidget);
    expect(find.text('Utiliser mon adresse email'), findsOneWidget);

    // Switch to email mode
    await tester.tap(find.text('Utiliser mon adresse email'));
    await tester.pumpAndSettle();

    expect(find.text('ADRESSE EMAIL'), findsOneWidget);
    expect(find.text('Utiliser mon numéro de téléphone'), findsOneWidget);

    // Enter email and send
    await tester.enterText(find.byType(TextField), 'test@miva.tg');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    expect(repo.sentIdentifier, 'test@miva.tg');
    expect(find.text('Code envoyé !'), findsOneWidget);
    expect(find.text('Entrer le code'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen auto-selects email when initialIdentifier is an email',
      (tester) async {
    final repo = _TestMerchantAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBrightnessProvider.overrideWithValue(Brightness.light),
          merchantAuthProvider.overrideWith(
            (ref) => MerchantAuthNotifier(repo),
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
          home: const ForgotPasswordScreen(
            initialIdentifier: 'merchant@domain.com',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ADRESSE EMAIL'), findsOneWidget);
    expect(find.text('merchant@domain.com'), findsOneWidget);
  });
}
