class SmsCampaignModel {
  const SmsCampaignModel({
    required this.id,
    required this.merchantId,
    required this.message,
    this.recipientType,
    this.recipientIds,
    this.recipientsCount = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.status = 'draft',
    this.scheduledAt,
    this.sentAt,
    required this.createdAt,
  });

  final String id;
  final String merchantId;
  final String message;
  final String? recipientType; // 'all'|'near_reward'|'inactive'|'manual'
  final List<String>? recipientIds;
  final int recipientsCount;

  /// Nombre de destinataires réellement notifiés avec succès (push FCM
  /// délivré) — vient de `notification_logs`, distinct de [recipientsCount]
  /// (la cible calculée à la création, avant tout envoi).
  final int deliveredCount;

  /// Nombre d'échecs (pas de token enregistré, envoi FCM rejeté...).
  final int failedCount;
  final String status; // 'draft'|'sent'|'scheduled'
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isScheduled => status == 'scheduled';

  /// Construit une campagne depuis `GET /merchant/campaigns`. Les dates y
  /// arrivent au format SQL comme ISO selon l'origine (colonne brute ou
  /// accesseur), d'où le `tryParse` plutôt qu'un `parse` strict.
  factory SmsCampaignModel.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        DateTime.tryParse(json[key]?.toString() ?? '');

    return SmsCampaignModel(
      id: json['id'].toString(),
      merchantId: json['merchant_id']?.toString() ?? '',
      message: json['message'] as String? ?? '',
      recipientType: json['recipient_type'] as String?,
      recipientIds: json['recipient_ids'] is List
          ? (json['recipient_ids'] as List).map((e) => e.toString()).toList()
          : null,
      recipientsCount: json['recipients_count'] as int? ?? 0,
      deliveredCount: json['delivered_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      scheduledAt: date('scheduled_at'),
      sentAt: date('sent_at'),
      createdAt: date('created_at') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant_id': merchantId,
      'message': message,
      'recipient_type': recipientType,
      'recipient_ids': recipientIds,
      'recipients_count': recipientsCount,
      'status': status,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
