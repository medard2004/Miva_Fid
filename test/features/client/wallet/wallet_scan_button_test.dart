import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:miva_fid/core/theme/app_theme.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/wallet/wallet_dashboard_screen.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

class _FakeWalletNotifier extends StateNotifier<List<LoyaltyCard>>
    implements WalletNotifier {
  _FakeWalletNotifier(super.initialCards);

  @override
  Future<void> loadMine() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('WalletDashboardScreen has floating scan button with exact main2 responsive position',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBrightnessProvider.overrideWithValue(Brightness.light),
          walletProvider.overrideWith((ref) => _FakeWalletNotifier(const [])),
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
          home: const WalletDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify floating action button exists
    final fab = find.byType(IconButton);
    expect(fab, findsWidgets);

    final scanIcon = find.byIcon(LucideIcons.scanLine);
    expect(scanIcon, findsWidgets);

    // Verify FAB padding: bottom 74, right 6 (from main2 reference commit e2c65114)
    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.floatingActionButton, isNotNull);

    final fabPadding = scaffold.floatingActionButton as Padding;
    expect(fabPadding.padding, const EdgeInsets.only(bottom: 74, right: 6));
  });
}
