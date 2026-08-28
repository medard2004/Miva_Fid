import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/client/models/reward.dart';

/// Fixtures capturées mot pour mot depuis `GET /api/rewards` sur un vrai
/// serveur Laravel (avant/après validation marchand) — vérifie que le
/// modèle Flutter parse réellement le format renvoyé, pas une supposition.
void main() {
  group('Reward.fromApi — payload réel GET /rewards', () {
    test('parses an available, non-expired reward', () {
      final json = {
        'id': 1,
        'loyalty_card_id': 1,
        'restaurant_id': 1,
        'title': 'Café QA offert',
        'status': 'available',
        'redeem_token': 'e6d5a793-c852-4efe-b38a-cd1b865e8e14',
        'unlocked_at': '2026-08-20T01:20:51.000000Z',
        'expires_at': '2026-09-19T01:20:51.000000Z',
        'used_at': null,
        'is_expired': false,
        'restaurant': {'id': 1, 'name': 'QA Test Resto'},
      };

      final reward = Reward.fromApi(json);

      expect(reward.id, '1');
      expect(reward.cardId, '1');
      expect(reward.restaurantName, 'QA Test Resto');
      expect(reward.title, 'Café QA offert');
      expect(reward.status, RewardStatus.available);
      expect(reward.isExpired, false);
      expect(reward.redeemToken, 'e6d5a793-c852-4efe-b38a-cd1b865e8e14');
      expect(reward.isRedeemable, true);
      expect(reward.usedAt, isNull);
      expect(reward.expiresAt, isNotNull);
      expect(reward.isBirthday, false);
    });

    test('marks a birthday reward via source', () {
      final json = {
        'id': 2,
        'loyalty_card_id': 1,
        'restaurant_id': 1,
        'source': 'birthday',
        'title': 'Joyeux anniversaire 🎂',
        'status': 'available',
        'redeem_token': 'a1b2c3',
        'unlocked_at': '2026-08-28T08:00:00.000000Z',
        'expires_at': null,
        'used_at': null,
        'is_expired': false,
        'restaurant': {'id': 1, 'name': 'QA Test Resto'},
      };

      final reward = Reward.fromApi(json);

      expect(reward.isBirthday, true);
      expect(reward.isSurprise, false);
    });

    test('marks a surprise reward via is_surprise, title already masked by the server', () {
      final json = {
        'id': 3,
        'loyalty_card_id': 1,
        'restaurant_id': 1,
        'source': 'birthday',
        'is_surprise': true,
        'title': '🎁 Récompense surprise',
        'status': 'available',
        'redeem_token': 'd4e5f6',
        'unlocked_at': '2026-08-28T08:00:00.000000Z',
        'expires_at': null,
        'used_at': null,
        'is_expired': false,
        'restaurant': {'id': 1, 'name': 'QA Test Resto'},
      };

      final reward = Reward.fromApi(json);

      expect(reward.isSurprise, true);
      expect(reward.title, '🎁 Récompense surprise');
    });

    test('parses a reward after merchant validation (used)', () {
      final json = {
        'id': 1,
        'loyalty_card_id': 1,
        'restaurant_id': 1,
        'title': 'Café QA offert',
        'status': 'used',
        'redeem_token': 'e6d5a793-c852-4efe-b38a-cd1b865e8e14',
        'unlocked_at': '2026-08-20T01:20:51.000000Z',
        'expires_at': '2026-09-19T01:20:51.000000Z',
        'used_at': '2026-08-20T01:21:19.000000Z',
        'is_expired': false,
        'restaurant': {'id': 1, 'name': 'QA Test Resto'},
      };

      final reward = Reward.fromApi(json);

      expect(reward.status, RewardStatus.used);
      expect(reward.isRedeemable, false);
      expect(reward.usedAt, isNotNull);
    });

    test('an expired-but-available reward is not redeemable', () {
      final json = {
        'id': 2,
        'loyalty_card_id': 1,
        'restaurant_id': 1,
        'title': 'Ancienne offre',
        'status': 'available',
        'redeem_token': 'abc-123',
        'unlocked_at': '2026-01-01T00:00:00.000000Z',
        'expires_at': '2026-01-31T00:00:00.000000Z',
        'used_at': null,
        'is_expired': true,
        'restaurant': {'id': 1, 'name': 'QA Test Resto'},
      };

      final reward = Reward.fromApi(json);

      expect(reward.status, RewardStatus.available);
      expect(reward.isExpired, true);
      expect(reward.isRedeemable, false);
    });

    test('a canceled reward is not redeemable', () {
      final json = {
        'id': 3,
        'loyalty_card_id': 1,
        'restaurant_id': 1,
        'title': 'Erreur de saisie',
        'status': 'canceled',
        'redeem_token': 'def-456',
        'unlocked_at': '2026-08-01T00:00:00.000000Z',
        'expires_at': null,
        'used_at': null,
        'is_expired': false,
        'restaurant': {'id': 1, 'name': 'QA Test Resto'},
      };

      final reward = Reward.fromApi(json);

      expect(reward.status, RewardStatus.canceled);
      expect(reward.isRedeemable, false);
    });
  });
}
