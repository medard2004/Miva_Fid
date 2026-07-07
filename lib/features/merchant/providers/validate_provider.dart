import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/loyalty_card_model.dart';
import 'dashboard_stats_provider.dart' show dashboardStatsProvider;
import 'merchant_provider.dart';

part 'validate_provider.g.dart';

@riverpod
class ValidateNotifier extends _$ValidateNotifier {
  @override
  void build() {}

  Future<LoyaltyCardModel?> lookupClient(String clientId) async {
    final merchant = await ref.read(merchantNotifierProvider.future);
    if (merchant == null) return null;
    final res = await Supabase.instance.client
        .from('loyalty_cards')
        .select('*, users(*)')
        .eq('client_id', clientId)
        .eq('merchant_id', merchant.id)
        .maybeSingle();
    if (res == null) return null;
    return LoyaltyCardModel.fromJson(res);
  }

  Future<LoyaltyCardModel?> lookupByCode(String code) async {
    final res = await Supabase.instance.client
        .from('users')
        .select('id')
        .ilike('id', '%${code.toLowerCase()}%')
        .maybeSingle();
    if (res == null) return null;
    return lookupClient(res['id'] as String);
  }

  Future<int> addStamp(String cardId) async {
    final merchant = await ref.read(merchantNotifierProvider.future);
    if (merchant == null) throw Exception('Marchand non trouvé');

    await Supabase.instance.client.from('stamps').insert({
      'card_id': cardId,
      'merchant_id': merchant.id,
      'validated_by': Supabase.instance.client.auth.currentUser?.id,
    });

    final card = await Supabase.instance.client
        .from('loyalty_cards')
        .select('stamps_count')
        .eq('id', cardId)
        .single();

    final newCount = (card['stamps_count'] as int? ?? 0);

    if (newCount >= merchant.stampsRequired) {
      await Supabase.instance.client.from('rewards').insert({
        'card_id': cardId,
        'client_id': (await Supabase.instance.client
                .from('loyalty_cards')
                .select('client_id')
                .eq('id', cardId)
                .single())['client_id'],
        'merchant_id': merchant.id,
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'redemption_code': _generateCode(),
        'status': 'available',
      });
      await Supabase.instance.client
          .from('loyalty_cards')
          .update({'stamps_count': 0, 'status': 'reward_available'})
          .eq('id', cardId);
    }

    ref.invalidate(dashboardStatsProvider);
    return newCount;
  }

  String _generateCode() =>
      List.generate(6, (_) => Random().nextInt(10)).join();
}
