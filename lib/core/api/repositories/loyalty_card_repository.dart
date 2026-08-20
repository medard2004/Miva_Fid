import '../services/loyalty_card_service.dart';
import '../../../features/client/models/loyalty_card.dart';

/// Résultat de `POST /loyalty-cards/join` — [isNew] distingue une carte tout
/// juste créée d'une carte déjà existante (le join est idempotent côté
/// serveur, `firstOrCreate` renvoie la même carte sans erreur).
class JoinCardResult {
  final LoyaltyCard card;
  final bool isNew;

  const JoinCardResult({required this.card, required this.isNew});
}

class LoyaltyCardRepository {
  final LoyaltyCardService _service;

  LoyaltyCardRepository(this._service);

  /// Parse chaque carte individuellement : une seule carte malformée (champ
  /// legacy manquant, type inattendu) ne doit pas faire disparaître tout le
  /// wallet du client.
  Future<List<LoyaltyCard>> listMine() async {
    final rows = await _service.listMine();
    final cards = <LoyaltyCard>[];
    for (final row in rows) {
      try {
        cards.add(LoyaltyCard.fromApi(row));
      } catch (_) {}
    }
    return cards;
  }

  Future<JoinCardResult> joinByQrToken(String qrToken) async {
    final response = await _service.joinByQrToken(qrToken);
    return JoinCardResult(
      card: LoyaltyCard.fromApi(response['card'] as Map<String, dynamic>),
      isNew: response['was_recently_created'] as bool? ?? true,
    );
  }

  Future<LoyaltyCard> getCard(String id) async {
    final response = await _service.getCard(id);
    return LoyaltyCard.fromApi(response['card'] as Map<String, dynamic>);
  }
}
