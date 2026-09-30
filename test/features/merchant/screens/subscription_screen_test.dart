import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miva_fid/core/theme/app_theme.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/merchant/screens/subscription_screen.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('SubscriptionScreen renders "Service bientôt disponible" and current features',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBrightnessProvider.overrideWithValue(Brightness.light),
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
          home: const SubscriptionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Service bientôt disponible'), findsOneWidget);
    expect(find.textContaining('La gestion des formules d\'abonnement sera prochainement accessible'), findsOneWidget);
    expect(find.text('Actuellement inclus :'), findsOneWidget);
    expect(find.text('Programme de fidélité complet & cartes illimitées'), findsOneWidget);
    expect(find.text('Campagnes de notifications push & SMS'), findsOneWidget);
    expect(find.text('Gestion d\'équipe & droits d\'accès'), findsOneWidget);
    expect(find.text('Statistiques en direct & suivi client'), findsOneWidget);
    expect(find.text('Retour au menu'), findsOneWidget);
  });
}
