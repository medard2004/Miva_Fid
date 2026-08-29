import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/client/models/referral.dart';

void main() {
  group('Referral.fromJson', () {
    test('parses a pending referral', () {
      final referral = Referral.fromJson({
        'id': 1,
        'status': 'pending',
        'restaurant': {'name': 'Chez Awa'},
        'referred_client': {'first_name': 'Kofi'},
        'reward': null,
        'validated_at': null,
        'created_at': '2026-08-29T10:00:00Z',
      });

      expect(referral.id, '1');
      expect(referral.status, ReferralStatus.pending);
      expect(referral.restaurantName, 'Chez Awa');
      expect(referral.referredName, 'Kofi');
      expect(referral.rewardTitle, isNull);
      expect(referral.validatedAt, isNull);
    });

    test('parses a validated referral with its reward title', () {
      final referral = Referral.fromJson({
        'id': 2,
        'status': 'validated',
        'restaurant': {'name': 'Chez Awa'},
        'referred_client': {'first_name': 'Ama'},
        'reward': {'title': 'Café offert'},
        'validated_at': '2026-08-29T12:00:00Z',
      });

      expect(referral.status, ReferralStatus.validated);
      expect(referral.rewardTitle, 'Café offert');
      expect(referral.validatedAt, DateTime.parse('2026-08-29T12:00:00Z'));
    });

    test('missing restaurant/referred_client fall back to empty strings', () {
      final referral = Referral.fromJson({'id': 3, 'status': 'pending'});

      expect(referral.restaurantName, '');
      expect(referral.referredName, '');
    });
  });
}
