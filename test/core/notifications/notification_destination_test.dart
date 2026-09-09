import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/notifications/notification_destination.dart';

void main() {
  group('resolveNotificationDestination', () {
    test('reward_unlocked with reward_id resolves to RewardDestination', () {
      final dest = resolveNotificationDestination(
        type: 'reward_unlocked',
        data: {'reward_id': 42},
        title: 'Titre',
        body: 'Corps',
      );
      expect(dest, isA<RewardDestination>());
      expect((dest as RewardDestination).rewardId, '42');
    });

    test('birthday with reward_id resolves to RewardDestination', () {
      final dest = resolveNotificationDestination(
        type: 'birthday',
        data: {'reward_id': 7},
        title: 'Titre',
        body: 'Corps',
      );
      expect(dest, isA<RewardDestination>());
    });

    test('birthday without reward_id falls back to InboxDestination', () {
      final dest = resolveNotificationDestination(
        type: 'birthday',
        data: const {},
        title: 'Titre',
        body: 'Corps',
      );
      expect(dest, isA<InboxDestination>());
    });

    test('campaign with campaign_id resolves to CampaignDestination carrying the notification text', () {
      final dest = resolveNotificationDestination(
        type: 'campaign',
        data: {'campaign_id': 9},
        title: 'Promo',
        body: 'Ce week-end -15%',
      );
      expect(dest, isA<CampaignDestination>());
      final campaign = dest as CampaignDestination;
      expect(campaign.campaignId, '9');
      expect(campaign.title, 'Promo');
      expect(campaign.body, 'Ce week-end -15%');
    });

    test('referral_pending and referral_validated resolve to ReferralDestination', () {
      expect(
        resolveNotificationDestination(type: 'referral_pending', data: const {}, title: '', body: ''),
        isA<ReferralDestination>(),
      );
      expect(
        resolveNotificationDestination(type: 'referral_validated', data: const {}, title: '', body: ''),
        isA<ReferralDestination>(),
      );
    });

    test('cashback_received with card_id resolves to CardDestination (generic card_id rule)', () {
      final dest = resolveNotificationDestination(
        type: 'cashback_received',
        data: {'card_id': 3},
        title: '',
        body: '',
      );
      expect(dest, isA<CardDestination>());
      expect((dest as CardDestination).cardId, '3');
    });

    test('level_up with card_id resolves to CardDestination', () {
      final dest = resolveNotificationDestination(
        type: 'level_up',
        data: {'card_id': 5, 'level_name': 'Or'},
        title: '',
        body: '',
      );
      expect(dest, isA<CardDestination>());
    });

    test('any unknown future type carrying card_id still resolves to CardDestination', () {
      final dest = resolveNotificationDestination(
        type: 'some_future_type',
        data: {'card_id': 11},
        title: '',
        body: '',
      );
      expect(dest, isA<CardDestination>());
    });

    test('admin_broadcast (no card_id) falls back to InboxDestination', () {
      final dest = resolveNotificationDestination(
        type: 'admin_broadcast',
        data: const {},
        title: '',
        body: '',
      );
      expect(dest, isA<InboxDestination>());
    });

    test('unknown type without any usable data falls back to InboxDestination', () {
      final dest = resolveNotificationDestination(
        type: 'totally_unknown',
        data: const {},
        title: '',
        body: '',
      );
      expect(dest, isA<InboxDestination>());
    });
  });
}
