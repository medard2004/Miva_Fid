import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/loyalty_card_model.dart';
import 'merchant_provider.dart';

part 'clients_provider.g.dart';

@riverpod
class ClientsNotifier extends _$ClientsNotifier {
  String _q = '';
  String _filter = 'Tous';

  @override
  Future<List<LoyaltyCardModel>> build() async {
    final merchant = await ref.watch(merchantNotifierProvider.future);
    if (merchant == null) return [];

    var query = Supabase.instance.client
        .from('loyalty_cards')
        .select('*, users(*)')
        .eq('merchant_id', merchant.id)
        .order('created_at', ascending: false);

    final res = await query;
    var cards = (res as List)
        .cast<Map<String, dynamic>>()
        .map(LoyaltyCardModel.fromJson)
        .toList();

    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      cards = cards.where((c) {
        final name = c.client?.name.toLowerCase() ?? '';
        return name.contains(q);
      }).toList();
    }

    if (_filter == 'Proches récompense') {
      cards = cards.where((c) {
        final ratio = c.stampsCount / (merchant.stampsRequired);
        return ratio >= 0.8 && ratio < 1.0;
      }).toList();
    } else if (_filter == 'Inactifs') {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      cards = cards.where((c) => c.createdAt.isBefore(thirtyDaysAgo)).toList();
    }

    return cards;
  }

  void search(String q) {
    _q = q;
    ref.invalidateSelf();
  }

  void setFilter(String f) {
    _filter = f;
    ref.invalidateSelf();
  }

  Future<void> addBonusStamp(String cardId) async {
    final merchant = await ref.read(merchantNotifierProvider.future);
    if (merchant == null) return;
    await Supabase.instance.client.from('stamps').insert({
      'card_id': cardId,
      'merchant_id': merchant.id,
      'validated_by': Supabase.instance.client.auth.currentUser?.id,
    });
    ref.invalidateSelf();
  }
}
