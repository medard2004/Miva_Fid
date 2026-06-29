class StampModel {
  const StampModel({
    required this.id,
    required this.cardId,
    required this.merchantId,
    this.validatedBy,
    required this.validatedAt,
  });

  final String id;
  final String cardId;
  final String merchantId;
  final String? validatedBy;
  final DateTime validatedAt;

  factory StampModel.fromJson(Map<String, dynamic> json) {
    return StampModel(
      id: json['id'] as String,
      cardId: json['card_id'] as String,
      merchantId: json['merchant_id'] as String,
      validatedBy: json['validated_by'] as String?,
      validatedAt: DateTime.parse(json['validated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_id': cardId,
      'merchant_id': merchantId,
      'validated_by': validatedBy,
      'validated_at': validatedAt.toIso8601String(),
    };
  }
}
