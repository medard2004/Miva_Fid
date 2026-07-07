import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/merchant_model.dart';

part 'merchant_provider.g.dart';

@Riverpod(keepAlive: true)
class MerchantNotifier extends _$MerchantNotifier {
  @override
  Future<MerchantModel?> build() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await Supabase.instance.client
        .from('merchants')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return data != null ? MerchantModel.fromJson(data) : null;
  }

  Future<void> createMerchant(Map<String, dynamic> json) async {
    final res = await Supabase.instance.client
        .from('merchants')
        .insert(json)
        .select()
        .single();
    state = AsyncData(MerchantModel.fromJson(res));
  }

  Future<void> updateProgramme(Map<String, dynamic> data) async {
    final id = state.value?.id;
    if (id == null) return;
    await Supabase.instance.client.from('merchants').update(data).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> uploadLogo(String filePath) async {
    final id = state.value?.id;
    if (id == null) return;
    final bytes = await _readFile(filePath);
    final path = 'logos/$id.jpg';
    await Supabase.instance.client.storage.from('merchant-assets').uploadBinary(path, Uint8List.fromList(bytes));
    final url = Supabase.instance.client.storage.from('merchant-assets').getPublicUrl(path);
    await updateProgramme({'logo_url': url});
  }

  Future<List<int>> _readFile(String path) async => [];
}
