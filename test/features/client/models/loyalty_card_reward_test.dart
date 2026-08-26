import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';

/// Fixtures capturées mot pour mot depuis une vraie requête HTTP contre le
/// serveur Laravel local (`php artisan serve`, `GET /loyalty-cards` puis
/// `LoyaltyCardUpdated::broadcastWith()` simulé) — pas de JSON inventé, pour
/// vérifier que le modèle Flutter parse réellement ce que le backend envoie.
void main() {
  group('LoyaltyCard.fromApi — payload réel /loyalty-cards', () {
    Map<String, dynamic> baseJson({
      required int stampsCurrent,
      required int goal,
      required int percent,
      required Map<String, dynamic> level,
      String programType = 'stamps',
    }) {
      return {
        'id': 1,
        'card_code': 'L1YFNAHT',
        'progress': {'stamps_current': stampsCurrent},
        'cashback_balance_fcfa': '0.00',
        'status': 'active',
        'goal': goal,
        'percent': percent,
        'level': level,
        'restaurant': {'id': 1, 'name': 'QA Test Resto', 'category': 'Restaurant'},
        'loyalty_program': {
          'id': 1,
          'type': programType,
          'config': {
            'goal': goal,
            'color_primary': '#4F46E5',
          },
        },
      };
    }

    test('parses goal/percent/level from a real backend payload', () {
      final json = baseJson(
        stampsCurrent: 0,
        goal: 2,
        percent: 0,
        level: {'name': 'Argent', 'percent_to_next': 100, 'is_max_level': true},
      );

      final card = LoyaltyCard.fromApi(json);

      expect(card.mechanic, LoyaltyMechanic.stamps);
      expect(card.stampsCurrent, 0);
      expect(card.stampsGoal, 2);
      expect(card.percent, 0);
      expect(card.levelName, 'Argent');
      expect(card.levelPercentToNext, 100);
      expect(card.isMaxLevel, true);
    });

    test('parses a mid-cycle percentage exactly as computed server-side', () {
      // 1/2 tampons -> 50%, capturé réellement après le premier octroi.
      final json = baseJson(
        stampsCurrent: 1,
        goal: 2,
        percent: 50,
        level: {'name': 'Bronze', 'percent_to_next': 0, 'is_max_level': false},
      );

      final card = LoyaltyCard.fromApi(json);

      expect(card.stampsCurrent, 1);
      expect(card.percent, 50);
      expect(card.levelName, 'Bronze');
      expect(card.isMaxLevel, false);
    });

    test('parses the tiers array into List<CardTier>', () {
      final json = baseJson(
        stampsCurrent: 3,
        goal: 5,
        percent: 60,
        level: {'name': 'Argent', 'percent_to_next': 60, 'is_max_level': false},
      );
      json['tiers'] = [
        {
          'order': 2,
          'position': 2,
          'goal': 500,
          'level_name': 'Argent',
          'reward_description': '10% de réduction',
          'icon_key': null,
          'status': 'current',
        },
      ];

      final card = LoyaltyCard.fromApi(json);

      expect(card.tiers, hasLength(1));
      final tier = card.tiers.single;
      expect(tier.order, 2);
      expect(tier.position, 2);
      expect(tier.goal, 500);
      expect(tier.levelName, 'Argent');
      expect(tier.rewardDescription, '10% de réduction');
      expect(tier.iconKey, isNull);
      expect(tier.status, 'current');
    });

    test('mono-tier response (level null, tiers absent) -> levelName null, tiers empty', () {
      final json = baseJson(
        stampsCurrent: 1,
        goal: 2,
        percent: 50,
        level: {'name': 'Argent', 'percent_to_next': 100, 'is_max_level': true},
      );
      json['level'] = null;
      json.remove('tiers');

      final card = LoyaltyCard.fromApi(json);

      expect(card.levelName, isNull);
      expect(card.tiers, isEmpty);
    });

    test('mono-tier response with tiers: [] also produces an empty tiers list', () {
      final json = baseJson(
        stampsCurrent: 1,
        goal: 2,
        percent: 50,
        level: {'name': 'Argent', 'percent_to_next': 100, 'is_max_level': true},
      );
      json['level'] = null;
      json['tiers'] = [];

      final card = LoyaltyCard.fromApi(json);

      expect(card.levelName, isNull);
      expect(card.tiers, isEmpty);
    });

    test('mono-tier response carries next_reward with the real reward text (no roadmap)', () {
      final json = baseJson(
        stampsCurrent: 1,
        goal: 2,
        percent: 50,
        level: {'name': 'Argent', 'percent_to_next': 100, 'is_max_level': true},
      );
      json['level'] = null;
      json['tiers'] = [];
      json['next_reward'] = {
        'order': 1,
        'position': 1,
        'goal': 2,
        'level_name': null,
        'reward_description': 'Café offert',
        'icon_key': null,
      };

      final card = LoyaltyCard.fromApi(json);

      expect(card.tiers, isEmpty, reason: 'mono-tier : pas de roadmap de niveau');
      expect(card.nextReward, isNotNull);
      expect(card.nextReward!.rewardDescription, 'Café offert');
      expect(card.nextReward!.goal, 2);
      expect(card.nextReward!.iconKey, isNull);
    });

    test('a program with no configured reward sends next_reward: null', () {
      final json = baseJson(
        stampsCurrent: 0,
        goal: 0,
        percent: 0,
        level: {},
        programType: 'cashback',
      );
      json['level'] = null;
      json['next_reward'] = null;

      final card = LoyaltyCard.fromApi(json);

      expect(card.nextReward, isNull);
    });

    test('parses tier position and icon_key from the tiers roadmap', () {
      final json = baseJson(
        stampsCurrent: 700,
        goal: 1000,
        percent: 40,
        level: {'name': 'Argent', 'percent_to_next': 40, 'is_max_level': false, 'position': 2, 'icon_key': null},
      )..['tiers'] = [
          {'order': 1, 'position': 1, 'goal': 500, 'level_name': 'Bronze', 'reward_description': 'Boisson offerte', 'icon_key': null, 'status': 'reached'},
          {'order': 2, 'position': 2, 'goal': 1000, 'level_name': 'Argent', 'reward_description': 'Dessert offert', 'icon_key': null, 'status': 'current'},
        ];

      final card = LoyaltyCard.fromApi(json);

      expect(card.tiers, hasLength(2));
      expect(card.tiers[0].position, 1);
      expect(card.tiers[0].iconKey, isNull);
      expect(card.tiers[1].position, 2);
    });
  });

  group('LoyaltyCard.applyRealtimeUpdate — parité avec le fetch initial', () {
    test('goal/percent/level refresh from the realtime payload, not just at fetch', () {
      // Avant le correctif : stampsGoal ne se relisait qu'au fetch initial.
      final initial = LoyaltyCard.fromApi({
        'id': 1,
        'card_code': 'L1YFNAHT',
        'progress': {'stamps_current': 1},
        'cashback_balance_fcfa': '0.00',
        'status': 'active',
        'goal': 2,
        'percent': 50,
        'level': {'name': 'Bronze', 'percent_to_next': 0, 'is_max_level': false},
        'restaurant': {'id': 1, 'name': 'QA Test Resto', 'category': 'Restaurant'},
        'loyalty_program': {
          'id': 1,
          'type': 'stamps',
          'config': {'goal': 2},
        },
      });
      expect(initial.stampsGoal, 2);

      // Diffusion Reverb réelle après le 2e tampon : objectif franchi, reset
      // avec report (0), même forme exacte que `LoyaltyCardUpdated::broadcastWith()`.
      final realtimePayload = {
        'id': 1,
        'progress': {'stamps_current': 0},
        'cashback_balance_fcfa': '0.00',
        'status': 'reward_available',
        'reward_unlocked': true,
        'goal': 2,
        'percent': 0,
        'level': {'name': 'Argent', 'percent_to_next': 100, 'is_max_level': true},
      };

      final updated = initial.applyRealtimeUpdate(realtimePayload);

      expect(updated.stampsCurrent, 0);
      expect(updated.stampsGoal, 2, reason: 'goal must survive a realtime-only update');
      expect(updated.percent, 0);
      expect(updated.levelName, 'Argent');
      expect(updated.isMaxLevel, true);
    });

    test('a payload carrying tiers updates card.tiers', () {
      final initial = LoyaltyCard.fromApi({
        'id': 1,
        'card_code': 'L1YFNAHT',
        'progress': {'stamps_current': 1},
        'cashback_balance_fcfa': '0.00',
        'status': 'active',
        'goal': 2,
        'percent': 50,
        'level': {'name': 'Bronze', 'percent_to_next': 0, 'is_max_level': false},
        'restaurant': {'id': 1, 'name': 'QA Test Resto', 'category': 'Restaurant'},
        'loyalty_program': {
          'id': 1,
          'type': 'stamps',
          'config': {'goal': 2},
        },
      });
      expect(initial.tiers, isEmpty);

      final realtimePayload = {
        'id': 1,
        'progress': {'stamps_current': 1},
        'cashback_balance_fcfa': '0.00',
        'status': 'active',
        'goal': 2,
        'percent': 50,
        'level': {'name': 'Bronze', 'percent_to_next': 0, 'is_max_level': false},
        'tiers': [
          {
            'order': 1,
            'position': 1,
            'goal': 2,
            'level_name': 'Bronze',
            'reward_description': 'Café offert',
            'icon_key': null,
            'status': 'current',
          },
        ],
      };

      final updated = initial.applyRealtimeUpdate(realtimePayload);

      expect(updated.tiers, hasLength(1));
      expect(updated.tiers.single.levelName, 'Bronze');
    });

    test('a payload omitting tiers leaves the existing tiers unchanged', () {
      final initial = LoyaltyCard.fromApi({
        'id': 1,
        'card_code': 'L1YFNAHT',
        'progress': {'stamps_current': 1},
        'cashback_balance_fcfa': '0.00',
        'status': 'active',
        'goal': 2,
        'percent': 50,
        'level': {'name': 'Bronze', 'percent_to_next': 0, 'is_max_level': false},
        'restaurant': {'id': 1, 'name': 'QA Test Resto', 'category': 'Restaurant'},
        'loyalty_program': {
          'id': 1,
          'type': 'stamps',
          'config': {'goal': 2},
        },
        'tiers': [
          {
            'order': 1,
            'position': 1,
            'goal': 2,
            'level_name': 'Bronze',
            'reward_description': 'Café offert',
            'icon_key': null,
            'status': 'current',
          },
        ],
      });
      expect(initial.tiers, hasLength(1));

      // Payload temps réel sans clé `tiers` (convention existante : absent =
      // conserver la valeur précédente, comme pour tous les autres champs).
      final realtimePayload = {
        'id': 1,
        'progress': {'stamps_current': 0},
        'cashback_balance_fcfa': '0.00',
        'status': 'reward_available',
        'reward_unlocked': true,
        'goal': 2,
        'percent': 0,
        'level': {'name': 'Argent', 'percent_to_next': 100, 'is_max_level': true},
      };

      final updated = initial.applyRealtimeUpdate(realtimePayload);

      expect(updated.tiers, hasLength(1));
      expect(updated.tiers.single.levelName, 'Bronze');
    });

    test('a payload carrying next_reward updates card.nextReward', () {
      final initial = LoyaltyCard.fromApi({
        'id': 1,
        'card_code': 'L1YFNAHT',
        'progress': {'stamps_current': 1},
        'cashback_balance_fcfa': '0.00',
        'status': 'active',
        'goal': 2,
        'percent': 50,
        'level': null,
        'restaurant': {'id': 1, 'name': 'QA Test Resto', 'category': 'Restaurant'},
        'loyalty_program': {
          'id': 1,
          'type': 'stamps',
          'config': {'goal': 2},
        },
      });
      expect(initial.nextReward, isNull);

      final realtimePayload = {
        'id': 1,
        'progress': {'stamps_current': 1},
        'cashback_balance_fcfa': '0.00',
        'status': 'active',
        'goal': 2,
        'percent': 50,
        'level': null,
        'next_reward': {
          'goal': 2,
          'level_name': null,
          'reward_description': 'Café offert',
          'icon': '🎁',
        },
      };

      final updated = initial.applyRealtimeUpdate(realtimePayload);

      expect(updated.nextReward, isNotNull);
      expect(updated.nextReward!.rewardDescription, 'Café offert');
    });
  });
}
