import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user_model.dart';

part 'client_provider.g.dart';

@Riverpod(keepAlive: true)
class ClientNotifier extends _$ClientNotifier {
  @override
  Future<UserModel?> build() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      return UserModel(
        id: 'mock-client-id',
        name: 'Client Démo',
        phone: '90000000',
        role: 'client',
        createdAt: DateTime.now(),
      );
    }
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();
      return data != null
          ? UserModel.fromJson(data)
          : UserModel(
              id: uid,
              name: 'Client Démo',
              phone: '90000000',
              role: 'client',
              createdAt: DateTime.now(),
            );
    } catch (e) {
      return UserModel(
        id: uid,
        name: 'Client Démo',
        phone: '90000000',
        role: 'client',
        createdAt: DateTime.now(),
      );
    }
  }

  Future<void> scanMerchant(String merchantId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final existing = await Supabase.instance.client
        .from('loyalty_cards')
        .select('id')
        .eq('client_id', uid)
        .eq('merchant_id', merchantId)
        .maybeSingle();
    if (existing == null) {
      await Supabase.instance.client.from('loyalty_cards').insert({
        'client_id': uid,
        'merchant_id': merchantId,
        'stamps_count': 0,
        'status': 'active',
      });
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    await Supabase.instance.client.from('users').update(data).eq('id', uid);
    ref.invalidateSelf();
  }
}
