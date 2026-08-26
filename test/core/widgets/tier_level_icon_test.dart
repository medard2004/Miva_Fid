import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/domain/loyalty_level.dart';
import 'package:miva_fid/core/domain/tier_icon_palette.dart';
import 'package:miva_fid/core/widgets/tier_level_icon.dart';

void main() {
  Future<Icon> pumpAndGetIcon(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    return tester.widget<Icon>(find.byType(Icon));
  }

  testWidgets('renders the fixed LoyaltyLevel icon for position 1 to 5', (tester) async {
    final icon = await pumpAndGetIcon(tester, const TierLevelIcon(position: 1));
    expect(icon.icon, LoyaltyLevel.bronze.icon);
  });

  testWidgets('renders the palette icon for a custom tier beyond position 5', (tester) async {
    final icon = await pumpAndGetIcon(
      tester,
      const TierLevelIcon(position: null, iconKey: 'rocket_launch'),
    );
    expect(icon.icon, TierIconPalette.byKey('rocket_launch').icon);
  });

  testWidgets('falls back to the default palette icon when neither is known', (tester) async {
    final icon = await pumpAndGetIcon(tester, const TierLevelIcon(position: null, iconKey: null));
    expect(icon.icon, TierIconPalette.fallback.icon);
  });
}
