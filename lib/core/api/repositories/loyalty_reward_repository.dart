import '../services/loyalty_reward_service.dart';
import '../../cache/offline_cache_service.dart';
import '../../../features/client/models/reward.dart';

class LoyaltyRewardRepository {
  final LoyaltyRewardService _service;
  final OfflineCacheService? _cache;

  LoyaltyRewardRepository(this._service, [this._cache]);

  /// Parse chaque récompense individuellement : une seule ligne malformée
  /// ne doit pas faire disparaître toute la liste (même principe que
  /// `LoyaltyCardRepository.listMine`).
  Future<List<Reward>> listMine() async {
    try {
      final rows = await _service.listMine();
      await _cache?.saveClientRewards(rows);
      final rewards = <Reward>[];
      for (final row in rows) {
        try {
          rewards.add(Reward.fromApi(row));
        } catch (_) {}
      }
      return rewards;
    } catch (e) {
      if (_cache != null) {
        final cached = await _cache.getClientRewards();
        if (cached != null && cached.isNotEmpty) {
          final rewards = <Reward>[];
          for (final row in cached) {
            try {
              rewards.add(Reward.fromApi(row));
            } catch (_) {}
          }
          if (rewards.isNotEmpty) return rewards;
        }
      }
      rethrow;
    }
  }

  /// Récupère les récompenses stockées dans le cache SQLite sans appel réseau
  Future<List<Reward>> listFromCache() async {
    if (_cache == null) return [];
    final cached = await _cache.getClientRewards();
    if (cached == null || cached.isEmpty) return [];
    final rewards = <Reward>[];
    for (final row in cached) {
      try {
        rewards.add(Reward.fromApi(row));
      } catch (_) {}
    }
    return rewards;
  }
}

