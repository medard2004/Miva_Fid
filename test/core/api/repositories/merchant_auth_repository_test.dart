import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/api/repositories/merchant_auth_repository.dart';
import 'package:miva_fid/features/merchant/models/restaurant_account.dart';

void main() {
  group('mergeStaffLoginActor', () {
    test(
        'la réponse réelle du backend porte actor en frère de restaurant : '
        'RestaurantAccount.fromJson doit quand même reconnaître un opérateur',
        () {
      // Charge exactement telle que renvoyée par POST /auth/merchant/staff-login
      // aujourd'hui : `actor` à la racine, PAS imbriqué dans `restaurant`.
      final response = {
        'access_token': 'token-123',
        'restaurant': {
          'id': '1',
          'uuid': 'u1',
          'email': 'restaurant@a.com',
          'name': 'Chez Ama',
        },
        'actor': {
          'type': 'staff',
          'id': 5,
          'name': 'Jean Opérateur',
          'role': 'operator',
        },
      };

      final merged = mergeStaffLoginActor(response);
      final account = RestaurantAccount.fromJson(merged);

      expect(account.staffRole, 'operator');
      expect(account.actorType, 'staff');
      expect(account.staffName, 'Jean Opérateur');
    });

    test('si actor est déjà imbriqué dans restaurant (backend corrigé), on ne le perd pas', () {
      final response = {
        'access_token': 'token-123',
        'restaurant': {
          'id': '1',
          'uuid': 'u1',
          'email': 'restaurant@a.com',
          'actor': {
            'type': 'staff',
            'id': 5,
            'name': 'Jean Opérateur',
            'role': 'operator',
          },
        },
        // Le backend corrigé pourrait aussi ne plus renvoyer actor à la racine.
      };

      final merged = mergeStaffLoginActor(response);
      final account = RestaurantAccount.fromJson(merged);

      expect(account.staffRole, 'operator');
      expect(account.actorType, 'staff');
      expect(account.staffName, 'Jean Opérateur');
    });

    test('actor imbriqué a priorité sur un actor sœur contradictoire', () {
      final response = {
        'restaurant': {
          'id': '1', 'uuid': 'u1', 'email': 'a@a.com',
          'actor': {'type': 'staff', 'id': 5, 'name': 'Jean', 'role': 'operator'},
        },
        // Ne devrait jamais arriver en pratique, mais si le backend envoie
        // les deux, celui déjà imbriqué doit gagner (ne pas écraser).
        'actor': {'type': 'restaurant', 'id': null, 'name': null, 'role': 'admin'},
      };

      final merged = mergeStaffLoginActor(response);
      final account = RestaurantAccount.fromJson(merged);

      expect(account.staffRole, 'operator');
      expect(account.staffName, 'Jean');
    });

    test('sans actor du tout, retombe sur restaurant/admin (rétrocompatibilité)', () {
      final response = {
        'restaurant': {'id': '1', 'uuid': 'u1', 'email': 'a@a.com'},
      };

      final merged = mergeStaffLoginActor(response);
      final account = RestaurantAccount.fromJson(merged);

      expect(account.actorType, 'restaurant');
      expect(account.staffRole, 'admin');
    });
  });
}
