class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromApi(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['body'] as String,
        timestamp: DateTime.parse(json['created_at'] as String),
        isRead: json['read_at'] != null,
      );

  /// Horodatage relatif, ex. "il y a 2h".
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );
}
