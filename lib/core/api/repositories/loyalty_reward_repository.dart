import '../services/loyalty_reward_service.dart';
import '../../../features/client/models/reward.dart';

class LoyaltyRewardRepository {
  final LoyaltyRewardService _service;

  LoyaltyRewardRepository(this._service);

  /// Parse chaque récompense individuellement : une seule ligne malformée
  /// ne doit pas faire disparaître toute la liste (même principe que
  /// `LoyaltyCardRepository.listMine`).
  Future<List<Reward>> listMine() async {
    final rows = await _service.listMine();
    final rewards = <Reward>[];
    for (final row in rows) {
      try {
        rewards.add(Reward.fromApi(row));
      } catch (_) {}
    }
    return rewards;
  }
}
