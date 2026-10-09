import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';

void main() {
  group('LoyaltyCard — configuration de parrainage', () {
    Map<String, dynamic> buildCardJson({
      Map<String, dynamic>? referralReward,
      bool? referralRewardEnabled,
      String? referralRewardLabel,
    }) {
      return {
        'id': 1,
        'card_code': 'CARD123',
        'progress': {'stamps_current': 0},
        'status': 'active',
        'goal': 10,
        'restaurant': {'id': 1, 'name': 'Restaurant Test', 'category': 'Food'},
        'loyalty_program': {
          'id': 1,
          'type': 'stamps',
          'config': {
            'goal': 10,
            'color_primary': '#4F46E5',
            if (referralReward != null) 'referral_reward': referralReward,
            if (referralRewardEnabled != null)
              'referral_reward_enabled': referralRewardEnabled,
            if (referralRewardLabel != null)
              'referral_reward_label': referralRewardLabel,
          },
        },
      };
    }

    test('hasReferralReward is false quand aucune configuration n\'est fournie', () {
      final card = LoyaltyCard.fromApi(buildCardJson());
      expect(card.hasReferralReward, isFalse);
      expect(card.referralRewardLabel, isNull);
    });

    test('hasReferralReward is false si enabled est true mais sans label ni surprise', () {
      final card = LoyaltyCard.fromApi(
        buildCardJson(
          referralReward: {
            'enabled': true,
            'label': '',
            'surprise': false,
            'referred_enabled': false,
          },
        ),
      );
      expect(card.hasReferralReward, isFalse);
    });

    test('hasReferralReward is true si le parrain a une récompense configurée', () {
      final card = LoyaltyCard.fromApi(
        buildCardJson(
          referralReward: {
            'enabled': true,
            'label': '1 Café offert',
            'surprise': false,
          },
        ),
      );
      expect(card.hasReferralReward, isTrue);
      expect(card.referralRewardLabel, '1 Café offert');
      expect(card.isReferralRewardSurprise, isFalse);
    });

    test('hasReferralReward is true si le parrain a une récompense surprise', () {
      final card = LoyaltyCard.fromApi(
        buildCardJson(
          referralReward: {
            'enabled': true,
            'surprise': true,
          },
        ),
      );
      expect(card.hasReferralReward, isTrue);
      expect(card.isReferralRewardSurprise, isTrue);
    });

    test('hasReferralReward is true si seul le filleul a une récompense configurée', () {
      final card = LoyaltyCard.fromApi(
        buildCardJson(
          referralReward: {
            'enabled': false,
            'referred_enabled': true,
            'referred_label': '10% sur l\'addition',
          },
        ),
      );
      expect(card.hasReferralReward, isTrue);
      expect(card.referralReferredRewardLabel, '10% sur l\'addition');
    });

    test('hasReferralReward is false si le marchand a désactivé le parrainage', () {
      final card = LoyaltyCard.fromApi(
        buildCardJson(
          referralReward: {
            'enabled': false,
            'label': '1 Café offert',
            'referred_enabled': false,
          },
        ),
      );
      expect(card.hasReferralReward, isFalse);
    });
  });
}
