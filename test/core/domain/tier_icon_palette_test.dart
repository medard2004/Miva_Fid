import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/domain/tier_icon_palette.dart';

void main() {
  group('TierIconPalette.byKey', () {
    test('finds an option by its key', () {
      final option = TierIconPalette.byKey('rocket_launch');
      expect(option.key, 'rocket_launch');
    });

    test('falls back to a default icon for an unknown or null key', () {
      expect(TierIconPalette.byKey('does_not_exist').key, TierIconPalette.fallback.key);
      expect(TierIconPalette.byKey(null).key, TierIconPalette.fallback.key);
    });

    test('has no duplicate keys', () {
      final keys = TierIconPalette.options.map((o) => o.key).toList();
      expect(keys.toSet().length, keys.length);
    });
  });
}
