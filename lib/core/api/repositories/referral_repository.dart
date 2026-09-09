import '../services/referral_service.dart';
import '../../../features/client/models/referral.dart';

class ReferralRepository {
  final ReferralService _service;

  ReferralRepository(this._service);

  /// Parse chaque parrainage individuellement : une ligne malformée ne doit
  /// pas faire disparaître toute la liste (même précaution que
  /// `LoyaltyCardRepository.listMine`).
  Future<List<Referral>> listMine() async {
    final rows = await _service.listMine();
    final referrals = <Referral>[];
    for (final row in rows) {
      try {
        referrals.add(Referral.fromJson(row));
      } catch (_) {}
    }
    return referrals;
  }
}
