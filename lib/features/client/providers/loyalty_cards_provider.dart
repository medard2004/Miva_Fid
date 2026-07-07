import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/loyalty_card_model.dart';
import '../../../models/merchant_model.dart';

part 'loyalty_cards_provider.g.dart';

@riverpod
Future<List<LoyaltyCardModel>> loyaltyCards(LoyaltyCardsRef ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return _getMockCards();
  try {
    final res = await Supabase.instance.client
        .from('loyalty_cards')
        .select('*, merchants(*)')
        .eq('client_id', uid)
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(LoyaltyCardModel.fromJson)
        .toList();
  } catch (e) {
    return _getMockCards();
  }
}

List<LoyaltyCardModel> _getMockCards() {
  return [
    LoyaltyCardModel(
      id: 'mock-card-1',
      clientId: 'mock-client-id',
      merchantId: 'mock-merchant-1',
      stampsCount: 4,
      pointsTotal: 2000,
      status: 'active',
      createdAt: DateTime.now(),
      merchant: MerchantModel(
        id: 'mock-merchant-1',
        userId: 'mock-user-1',
        name: 'Supermarché Champion',
        category: 'Alimentation',
        address: 'Boulevard du 13 Janvier, Lomé',
        colorPrimary: '#4F46E5',
        colorSecondary: '#3730A3',
        loyaltyMode: 'stamps',
        stampsRequired: 10,
        rewardDescription: 'Bon d\'achat de 2000 FCFA',
        createdAt: DateTime.now(),
      ),
    ),
    LoyaltyCardModel(
      id: 'mock-card-2',
      clientId: 'mock-client-id',
      merchantId: 'mock-merchant-2',
      stampsCount: 8,
      pointsTotal: 4000,
      status: 'active',
      createdAt: DateTime.now(),
      merchant: MerchantModel(
        id: 'mock-merchant-2',
        userId: 'mock-user-2',
        name: 'Boulangerie Le Pain Doré',
        category: 'Restauration',
        address: 'Quartier Nyékonakpoé, Lomé',
        colorPrimary: '#F59E0B',
        colorSecondary: '#D97706',
        loyaltyMode: 'stamps',
        stampsRequired: 10,
        rewardDescription: '1 pain au chocolat offert',
        createdAt: DateTime.now(),
      ),
    ),
  ];
}

@riverpod
Future<LoyaltyCardModel?> loyaltyCardDetail(
    LoyaltyCardDetailRef ref, String cardId) async {
  try {
    final res = await Supabase.instance.client
        .from('loyalty_cards')
        .select('*, merchants(*)')
        .eq('id', cardId)
        .maybeSingle();
    if (res != null) return LoyaltyCardModel.fromJson(res);
  } catch (e) {
    // try to find in mock cards
  }
  final mocks = _getMockCards();
  return mocks.firstWhere((c) => c.id == cardId, orElse: () => mocks.first);
}
