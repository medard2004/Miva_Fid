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
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/models/merchant_model.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';
import 'package:miva_fid/features/merchant/providers/merchant_provider.dart';
import 'package:miva_fid/features/merchant/screens/profile_screen.dart';

class _FakeMerchantNotifier extends MerchantNotifier {
  @override
  Future<MerchantModel?> build() async => MerchantModel(
        id: '1',
        userId: 'u1',
        name: 'Chez Toto',
        category: 'restauration',
        createdAt: DateTime(2025),
      );
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
  testWidgets('ProfileScreen rend le formulaire sans planter', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBrightnessProvider.overrideWithValue(Brightness.light),
          merchantNotifierProvider.overrideWith(_FakeMerchantNotifier.new),
          merchantAuthProvider.overrideWith(
            (ref) => MerchantAuthNotifier(
              MerchantAuthRepository(
                MerchantAuthService(ApiClient(tokenStorage: _FakeTokenStorage())),
                _FakeTokenStorage(),
              ),
            ),
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
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NOM DU COMMERCE'), findsOneWidget);
    expect(find.text('Profil du commerce'), findsWidgets);
  });
}
