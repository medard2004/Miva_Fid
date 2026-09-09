/// Ligne de destinataire pour l'écran "Destinataires" du wizard de campagne
/// SMS — `GET /merchant/campaigns/recipients-list`.
class CampaignRecipientModel {
  const CampaignRecipientModel({
    required this.clientId,
    required this.name,
    this.phone,
    this.lastActivityAt,
    this.cyclesCompleted = 0,
  });

  final int clientId;
  final String name;
  final String? phone;
  final DateTime? lastActivityAt;
  final int cyclesCompleted;

  factory CampaignRecipientModel.fromJson(Map<String, dynamic> json) {
    return CampaignRecipientModel(
      clientId: json['client_id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      lastActivityAt: DateTime.tryParse(json['last_activity_at']?.toString() ?? ''),
      cyclesCompleted: json['cycles_completed'] as int? ?? 0,
    );
  }
}
