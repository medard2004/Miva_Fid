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
  });
}
