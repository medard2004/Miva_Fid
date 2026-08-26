import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/models/loyalty_card_model.dart';

void main() {
  group('LoyaltyCardModel.fromJson — level.position/icon_key', () {
    Map<String, dynamic> baseJson(Map<String, dynamic>? level) {
      return {
        'id': 1,
        'client_id': 1,
        'restaurant_id': 1,
        'created_at': '2026-08-01T00:00:00Z',
        'level': level,
      };
    }

    test('parses position and icon_key when a level is resolved', () {
      final card = LoyaltyCardModel.fromJson(baseJson({
        'name': 'Argent',
        'key': 'silver',
        'percent_to_next': 40,
        'is_max_level': false,
        'position': 2,
        'icon_key': null,
      }));

      expect(card.levelName, 'Argent');
      expect(card.levelPosition, 2);
      expect(card.levelIconKey, isNull);
    });

    test('exposes null position/icon_key when there is no level', () {
      final card = LoyaltyCardModel.fromJson(baseJson(null));

      expect(card.levelName, isNull);
      expect(card.levelPosition, isNull);
      expect(card.levelIconKey, isNull);
    });

    test('copyWith forwards levelPosition and levelIconKey unchanged', () {
      final card = LoyaltyCardModel.fromJson(baseJson({
        'name': 'Or', 'key': 'gold', 'percent_to_next': 10, 'is_max_level': false,
        'position': 3, 'icon_key': null,
      }));

      final copied = card.copyWith(levelName: 'Or');

      expect(copied.levelPosition, 3);
      expect(copied.levelIconKey, isNull);
    });
  });
}
