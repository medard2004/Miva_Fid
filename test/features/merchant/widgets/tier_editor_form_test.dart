import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/merchant/widgets/tier_editor_form.dart';
import 'package:miva_fid/features/onboarding/models/program_tier.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<ProgramTier> tiers) async {
    // Le formulaire est normalement hébergé dans un parent scrollable (voir
    // onboarding step2 / réglages marchand) ; ici, sans lui, une carte
    // dépliée dépasse la taille de test par défaut (800x600). On agrandit
    // la vue de test — même remède que `profile_router_test.dart` — sans
    // toucher au contenu ni aux assertions.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TierEditorForm(
          initialTiers: tiers,
          goalUnit: 'tampons',
          onChanged: (_) {},
        ),
      ),
    ));
  }

  testWidgets('positions 1 to 5 show a locked name, no editable field', (tester) async {
    await pump(tester, const [
      ProgramTier(goal: 500, levelName: 'Bronze', rewardDescription: 'A'),
      ProgramTier(goal: 1000, levelName: 'Argent', rewardDescription: 'B'),
    ]);
    // Déplie le premier palier.
    await tester.tap(find.text('Bronze').first);
    await tester.pumpAndSettle();

    expect(find.text('Nom du niveau *'), findsNothing);
    expect(find.text('Niveau : Bronze'), findsOneWidget);
  });

  testWidgets('position 6 shows a free name field and an icon picker trigger', (tester) async {
    await pump(tester, [
      const ProgramTier(goal: 100, levelName: 'Bronze', rewardDescription: 'A'),
      const ProgramTier(goal: 200, levelName: 'Argent', rewardDescription: 'B'),
      const ProgramTier(goal: 300, levelName: 'Or', rewardDescription: 'C'),
      const ProgramTier(goal: 400, levelName: 'Platine', rewardDescription: 'D'),
      const ProgramTier(goal: 500, levelName: 'Fidèle', rewardDescription: 'E'),
      const ProgramTier(goal: 600, levelName: 'Mon Palier Custom', rewardDescription: 'F'),
    ]);
    await tester.tap(find.text('Mon Palier Custom').first);
    await tester.pumpAndSettle();

    expect(find.text('Nom du niveau *'), findsOneWidget);
    expect(find.text('Choisir une icône'), findsOneWidget);
  });
}
