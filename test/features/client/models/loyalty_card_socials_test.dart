import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';

void main() {
  group('LoyaltyCard social profiles & page names', () {
    test('extracts custom page names from social_profiles payload', () {
      final json = {
        'id': 10,
        'card_code': 'TESTCARD',
        'status': 'active',
        'goal': 10,
        'percent': 50,
        'restaurant': {
          'id': 1,
          'name': 'Chez X',
          'social_profiles': {
            'facebook': {'name': 'Botega', 'link': 'https://facebook.com/botega'},
            'instagram': {'name': 'Chic Coin', 'link': 'chic_coin'},
            'tiktok': {'name': 'Chez X', 'link': 'chez_x'},
            'whatsapp': {'name': 'Service Client Botega', 'link': '+22890000000'},
          },
        },
        'loyalty_program': {
          'id': 1,
          'type': 'stamps',
          'config': {'goal': 10},
        },
      };

      final card = LoyaltyCard.fromApi(json);

      expect(card.restaurantFacebook, 'https://facebook.com/botega');
      expect(card.restaurantFacebookName, 'Botega');

      expect(card.restaurantInstagram, 'chic_coin');
      expect(card.restaurantInstagramName, 'Chic Coin');

      expect(card.restaurantTiktok, 'chez_x');
      expect(card.restaurantTiktokName, 'Chez X');

      expect(card.restaurantWhatsapp, '+22890000000');
      expect(card.restaurantWhatsappName, 'Service Client Botega');
    });

    test('falls back to restaurant name when page name is absent but link is provided', () {
      final json = {
        'id': 11,
        'card_code': 'TESTCARD2',
        'status': 'active',
        'restaurant': {
          'id': 2,
          'name': 'Botega Resto',
          'facebook': 'https://facebook.com/botega_resto',
          'instagram': 'botega_resto',
          'social_profiles': {
            'instagram': {'link': 'botega_resto'},
          },
        },
      };

      final card = LoyaltyCard.fromApi(json);

      // Facebook is from legacy column with no custom name -> falls back to restaurantName
      expect(card.restaurantFacebook, 'https://facebook.com/botega_resto');
      expect(card.restaurantFacebookName, 'Botega Resto');

      // Instagram has link in social_profiles without explicit name -> falls back to restaurantName
      expect(card.restaurantInstagram, 'botega_resto');
      expect(card.restaurantInstagramName, 'Botega Resto');
    });
  });
}
