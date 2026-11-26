import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/merchant/models/restaurant_account.dart';

void main() {
  group('RestaurantAccount.fromJson — champ actor', () {
    test('un compte Restaurant classique est actorType restaurant / role admin', () {
      final account = RestaurantAccount.fromJson({
        'id': '1', 'uuid': 'u1', 'email': 'a@a.com',
        'actor': {'type': 'restaurant', 'id': null, 'name': null, 'role': 'admin'},
      });

      expect(account.actorType, 'restaurant');
      expect(account.staffRole, 'admin');
      expect(account.staffName, isNull);
    });

    test('un compte opérateur porte son nom et son rôle', () {
      final account = RestaurantAccount.fromJson({
        'id': '1', 'uuid': 'u1', 'email': 'a@a.com',
        'actor': {'type': 'staff', 'id': 5, 'name': 'Jean', 'role': 'operator'},
      });

      expect(account.actorType, 'staff');
      expect(account.staffName, 'Jean');
      expect(account.staffRole, 'operator');
    });

    test('absence de la clé actor retombe sur restaurant/admin (rétrocompatibilité)', () {
      final account = RestaurantAccount.fromJson({
        'id': '1', 'uuid': 'u1', 'email': 'a@a.com',
      });

      expect(account.actorType, 'restaurant');
      expect(account.staffRole, 'admin');
    });

    test('social_profiles et autres maps envoyées en [] par Laravel ne plantent pas', () {
      final account = RestaurantAccount.fromJson({
        'id': 43,
        'uuid': 'u43',
        'email': 'merchant@example.com',
        'social_profiles': <dynamic>[],
        'opening_hours': <dynamic>[],
        'notification_preferences': <dynamic>[],
      });

      expect(account.id, '43');
      expect(account.socialProfiles, isEmpty);
      expect(account.openingHours, isEmpty);
      expect(account.notificationPreferences, isEmpty);
    });
  });
}
