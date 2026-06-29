class SmsCampaignModel {
  const SmsCampaignModel({
    required this.id,
    required this.merchantId,
    required this.message,
    this.recipientType,
    this.recipientIds,
    this.recipientsCount = 0,
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
  final String status; // 'draft'|'sent'|'scheduled'
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isScheduled => status == 'scheduled';

  factory SmsCampaignModel.fromJson(Map<String, dynamic> json) {
    return SmsCampaignModel(
      id: json['id'] as String,
      merchantId: json['merchant_id'] as String,
      message: json['message'] as String,
      recipientType: json['recipient_type'] as String?,
      recipientIds: (json['recipient_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      recipientsCount: json['recipients_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
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
