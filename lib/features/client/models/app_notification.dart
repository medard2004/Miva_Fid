class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  /// Payload de deep-link (`card_id`, `reward_id`, `campaign_id`...) — voir
  /// `resolveNotificationDestination`. `null`/vide pour un type sans donnée.
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  factory AppNotification.fromApi(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['body'] as String,
        timestamp: DateTime.parse(json['created_at'] as String),
        isRead: json['read_at'] != null,
        data: json['data'] is Map
            ? (json['data'] as Map).cast<String, dynamic>()
            : const {},
      );

  /// Horodatage relatif, ex. "il y a 2h".
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': message,
        'created_at': timestamp.toIso8601String(),
        'read_at': isRead ? DateTime.now().toIso8601String() : null,
        'data': data,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
        data: data,
      );
}
