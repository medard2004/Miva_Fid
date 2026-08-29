import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../models/campaign_recipient_model.dart';
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

  /// Liste hydratée des destinataires d'un segment, pour la page
  /// "Destinataires" du wizard (recherche + tri + cases à cocher).
  Future<List<CampaignRecipientModel>> fetchRecipients({
    required String recipientType,
    String? q,
    String sort = 'activity',
  }) {
    return ref.read(merchantDashboardServiceProvider).recipientsList(
          recipientType: recipientType,
          q: q,
          sort: sort,
        );
  }

  Future<void> sendCampaign({
    required String message,
    required String recipientType,
    required List<int> clientIds,
    DateTime? scheduledAt,
  }) async {
    await ref.read(merchantDashboardServiceProvider).sendCampaign(
          message: message,
          recipientType: recipientType,
          clientIds: clientIds,
          scheduledAt: scheduledAt,
        );
    // L'envoi débite le crédit SMS : recharger la session met le compteur
    // du dashboard à jour en même temps que la liste des campagnes.
    await ref.read(merchantNotifierProvider.notifier).refresh();
    ref.invalidateSelf();
  }

  /// Édite une campagne encore programmée (message/destinataires/date).
  Future<void> updateCampaign({
    required String campaignId,
    required String message,
    required String recipientType,
    required List<int> clientIds,
    required DateTime scheduledAt,
  }) async {
    await ref.read(merchantDashboardServiceProvider).updateCampaign(
          campaignId: campaignId,
          message: message,
          recipientType: recipientType,
          clientIds: clientIds,
          scheduledAt: scheduledAt,
        );
    ref.invalidateSelf();
  }

  /// Masque une campagne de l'historique (réversible côté serveur) —
  /// optimiste : retirée de la liste locale avant confirmation serveur,
  /// remise si l'appel échoue.
  Future<void> archive(String campaignId) async {
    final previous = state;
    state = AsyncData([
      for (final c in state.value ?? const [])
        if (c.id != campaignId) c,
    ]);
    try {
      await ref.read(merchantDashboardServiceProvider).archiveCampaign(campaignId);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}
