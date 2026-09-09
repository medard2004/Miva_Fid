import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/domain/loyalty_level.dart';

void main() {
  group('LoyaltyLevel.forPosition', () {
    test('maps positions 1 to 5 to the fixed canonical order', () {
      expect(LoyaltyLevel.forPosition(1), LoyaltyLevel.bronze);
      expect(LoyaltyLevel.forPosition(2), LoyaltyLevel.silver);
      expect(LoyaltyLevel.forPosition(3), LoyaltyLevel.gold);
      expect(LoyaltyLevel.forPosition(4), LoyaltyLevel.platinum);
      expect(LoyaltyLevel.forPosition(5), LoyaltyLevel.custom);
    });

    test('returns null beyond position 5', () {
      expect(LoyaltyLevel.forPosition(6), isNull);
      expect(LoyaltyLevel.forPosition(10), isNull);
    });
  });
}
