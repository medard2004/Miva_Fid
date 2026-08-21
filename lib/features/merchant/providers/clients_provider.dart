import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../models/loyalty_card_model.dart';
import 'merchant_auth_provider.dart';

part 'clients_provider.g.dart';

final hideMerchantNavProvider = StateProvider<bool>((ref) => false);

/// Clientèle du commerce connecté (`GET /merchant/clients`).
///
/// Recherche et filtre sont résolus côté serveur : le filtre « +30j » cible
/// les cartes sans activité récente, là où l'implémentation Supabase se
/// rabattait sur un `hashCode` de nom faute de données réelles.
@riverpod
class ClientsNotifier extends _$ClientsNotifier {
  String _q = '';
  String _filter = 'Tous';

  @override
  Future<List<LoyaltyCardModel>> build() async {
    final restaurant = ref.watch(
      merchantAuthProvider.select((s) => s.restaurant),
    );
    if (restaurant == null) return [];

    final rows = await ref.read(merchantDashboardServiceProvider).clients(
          search: _q,
          filter: _filter == '+30j' ? 'inactive_30d' : null,
        );
    return rows.map(LoyaltyCardModel.fromJson).toList();
  }

  void search(String q) {
    _q = q;
    ref.invalidateSelf();
  }

  void setFilter(String f) {
    _filter = f;
    ref.invalidateSelf();
  }

  /// Accorde un tampon depuis la fiche client.
  Future<void> addBonusStamp(String cardId) async {
    await ref.read(merchantDashboardServiceProvider).addStamp(cardId);
    ref.invalidateSelf();
  }
}
