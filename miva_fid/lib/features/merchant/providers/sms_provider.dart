import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/sms_campaign_model.dart';
import 'merchant_provider.dart';

part 'sms_provider.g.dart';

@riverpod
class SmsNotifier extends _$SmsNotifier {
  @override
  Future<List<SmsCampaignModel>> build() async {
    final merchant = await ref.watch(merchantNotifierProvider.future);
    if (merchant == null) return [];
    final res = await Supabase.instance.client
        .from('sms_campaigns')
        .select()
        .eq('merchant_id', merchant.id)
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SmsCampaignModel.fromJson)
        .toList();
  }

  Future<int> countRecipients(String recipientType) async {
    final merchant = await ref.read(merchantNotifierProvider.future);
    if (merchant == null) return 0;
    final res = await Supabase.instance.client
        .from('loyalty_cards')
        .select('id')
        .eq('merchant_id', merchant.id);
    return (res as List).length;
  }

  Future<void> sendCampaign({
    required String message,
    required String recipientType,
    DateTime? scheduledAt,
  }) async {
    final merchant = await ref.read(merchantNotifierProvider.future);
    if (merchant == null) return;
    final count = await countRecipients(recipientType);
    await Supabase.instance.client.from('sms_campaigns').insert({
      'merchant_id': merchant.id,
      'message': message,
      'recipient_type': recipientType,
      'recipients_count': count,
      'status': scheduledAt != null ? 'scheduled' : 'sent',
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': scheduledAt == null ? DateTime.now().toIso8601String() : null,
    });
    ref.invalidateSelf();
  }
}
