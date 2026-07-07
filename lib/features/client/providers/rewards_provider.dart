import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/reward_model.dart';

part 'rewards_provider.g.dart';

@riverpod
Future<List<RewardModel>> rewards(RewardsRef ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return _getMockRewards();
  try {
    final res = await Supabase.instance.client
        .from('rewards')
        .select()
        .eq('client_id', uid)
        .order('unlocked_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(RewardModel.fromJson)
        .toList();
  } catch (e) {
    return _getMockRewards();
  }
}

List<RewardModel> _getMockRewards() {
  return [
    RewardModel(
      id: 'mock-reward-1',
      cardId: 'mock-card-1',
      clientId: 'mock-client-id',
      merchantId: 'mock-merchant-1',
      unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
      redemptionCode: 'CHAMP10',
      status: 'available',
    ),
  ];
}

@riverpod
Future<RewardModel?> rewardDetail(RewardDetailRef ref, String rewardId) async {
  try {
    final res = await Supabase.instance.client
        .from('rewards')
        .select()
        .eq('id', rewardId)
        .maybeSingle();
    if (res != null) return RewardModel.fromJson(res);
  } catch (e) {
    // try to find in mock rewards
  }
  final mocks = _getMockRewards();
  return mocks.firstWhere((r) => r.id == rewardId, orElse: () => mocks.first);
}

@riverpod
class RewardsNotifier extends _$RewardsNotifier {
  @override
  Future<List<RewardModel>> build() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return _getMockRewards();
    try {
      final res = await Supabase.instance.client
          .from('rewards')
          .select()
          .eq('client_id', uid)
          .order('unlocked_at', ascending: false);
      return (res as List)
          .cast<Map<String, dynamic>>()
          .map(RewardModel.fromJson)
          .toList();
    } catch (e) {
      return _getMockRewards();
    }
  }

  Future<void> redeemReward(String rewardId) async {
    await Supabase.instance.client.from('rewards').update({
      'status': 'used',
      'redeemed_at': DateTime.now().toIso8601String(),
    }).eq('id', rewardId);
    ref.invalidateSelf();
  }

  Future<String> refreshCode(String rewardId) async {
    final code = List.generate(6, (_) => Random().nextInt(10)).join();
    await Supabase.instance.client.from('rewards').update({
      'redemption_code': code,
      'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    }).eq('id', rewardId);
    return code;
  }
}

@riverpod
Stream<int> countdown(CountdownRef ref, String rewardId) async* {
  int secs = 300;
  while (secs > 0) {
    await Future.delayed(const Duration(seconds: 1));
    secs--;
    yield secs;
  }
}
