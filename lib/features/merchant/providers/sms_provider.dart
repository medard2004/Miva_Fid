import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../models/sms_campaign_model.dart';
import 'merchant_auth_provider.dart';
import 'merchant_provider.dart';

part 'sms_provider.g.dart';

/// Campagnes SMS du commerce (`/merchant/campaigns`).
@riverpod
class SmsNotifier extends _$SmsNotifier {
  @override
  Future<List<SmsCampaignModel>> build() async {
    final restaurant = ref.watch(
      merchantAuthProvider.select((s) => s.restaurant),
    );
    if (restaurant == null) return [];

    final rows = await ref.read(merchantDashboardServiceProvider).campaigns();
    return rows.map(SmsCampaignModel.fromJson).toList();
  }

  /// Nombre de destinataires pour un ciblage donné — calculé par le serveur,
  /// jamais estimé côté app.
  Future<int> countRecipients(String recipientType) {
    return ref
        .read(merchantDashboardServiceProvider)
        .recipientCount(recipientType);
  }

  Future<void> sendCampaign({
    required String message,
    required String recipientType,
    DateTime? scheduledAt,
  }) async {
    await ref.read(merchantDashboardServiceProvider).sendCampaign(
          message: message,
          recipientType: recipientType,
          scheduledAt: scheduledAt,
        );
    // L'envoi débite le crédit SMS : recharger la session met le compteur
    // du dashboard à jour en même temps que la liste des campagnes.
    await ref.read(merchantNotifierProvider.notifier).refresh();
    ref.invalidateSelf();
  }
}
