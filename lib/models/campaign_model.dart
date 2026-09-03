class CampaignModel {
  const CampaignModel({
    required this.id,
    required this.merchantId,
    required this.type,
    this.title = '',
    required this.message,
    this.imageUrl,
    this.recipientType,
    this.recipientIds,
    this.recipientsCount = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.status = 'draft',
    this.scheduledAt,
    this.sentAt,
    required this.createdAt,
    this.draftStep = 1,
  });

  final String id;
  final String merchantId;
  final String type;
  final String title;
  final String message;
  final String? imageUrl;
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
  final int draftStep;

  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isScheduled => status == 'scheduled';

  /// Construit une campagne depuis `GET /merchant/campaigns`. Les dates y
  /// arrivent au format SQL comme ISO selon l'origine (colonne brute ou
  /// accesseur), d'où le `tryParse` plutôt qu'un `parse` strict.
  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final parsed = DateTime.tryParse(json[key]?.toString() ?? '');
      return parsed?.toLocal();
    }

    return CampaignModel(
      id: json['id'].toString(),
      merchantId: json['merchant_id']?.toString() ?? '',
      type: json['type'] as String? ?? 'promotion',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
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
      draftStep: json['draft_step'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant_id': merchantId,
      'type': type,
      'title': title,
      'message': message,
      'image_url': imageUrl,
      'recipient_type': recipientType,
      'recipient_ids': recipientIds,
      'recipients_count': recipientsCount,
      'status': status,
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'sent_at': sentAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'draft_step': draftStep,
    };
  }
}
