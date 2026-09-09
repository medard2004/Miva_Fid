import 'package:intl/intl.dart';

enum RewardStatus { available, used, canceled }

/// Récompense débloquée (cycle Tampons/Achats atteint), utilisable une
/// seule fois via [redeemToken] (QR affiché au marchand). L'expiration
/// n'est pas un statut séparé : [isExpired] est calculé côté serveur à la
/// lecture (voir `LoyaltyReward::getIsExpiredAttribute` côté API).
class Reward {
  final String id;
  final String? cardId;
  final String restaurantName;
  final String title;
  final RewardStatus status;
  final bool isExpired;
  final String redeemToken;
  final DateTime? unlockedAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;

  /// `true` pour une récompense offerte automatiquement le jour de
  /// l'anniversaire du client (voir `SendBirthdayNotifications` côté API),
  /// `false` pour une récompense de palier classique.
  final bool isBirthday;

  /// `true` = le titre est déjà masqué côté serveur (générique) tant que la
  /// récompense n'a pas été utilisée — voir `LoyaltyRewardController::index`.
  /// Sert uniquement à afficher une icône adaptée, `title` porte déjà le
  /// texte à montrer (réel ou générique selon le cas).
  final bool isSurprise;

  const Reward({
    required this.id,
    this.cardId,
    required this.restaurantName,
    required this.title,
    required this.status,
    required this.isExpired,
    required this.redeemToken,
    this.unlockedAt,
    this.expiresAt,
    this.usedAt,
    this.isBirthday = false,
    this.isSurprise = false,
  });

  /// Utilisable maintenant : disponible et non expirée.
  bool get isRedeemable => status == RewardStatus.available && !isExpired;

  bool get isExpiringSoon =>
      expiresAt != null && expiresAt!.difference(DateTime.now()).inHours < 48;

  /// [countdownPrefix] vient d'[AppLocalizations.commonCountdownPrefix]
  /// ("J-" en français, "D-" en anglais).
  String daysRemainingText(String countdownPrefix) {
    if (expiresAt == null) return '';
    final days = expiresAt!.difference(DateTime.now()).inDays;
    return '$countdownPrefix${days < 0 ? 0 : days}';
  }

  String formattedUsedDate(String dateFormatLocale) {
    if (usedAt == null) return '';
    return DateFormat('dd MMM yyyy', dateFormatLocale)
        .format(usedAt!)
        .toUpperCase();
  }

  factory Reward.fromApi(Map<String, dynamic> json) {
    final restaurant = json['restaurant'] as Map<String, dynamic>? ?? {};
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return Reward(
      id: json['id'].toString(),
      cardId: json['loyalty_card_id']?.toString(),
      restaurantName: restaurant['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: _statusFromApi(json['status'] as String?),
      isExpired: json['is_expired'] as bool? ?? false,
      redeemToken: json['redeem_token'] as String? ?? '',
      unlockedAt: parseDate(json['unlocked_at']),
      expiresAt: parseDate(json['expires_at']),
      usedAt: parseDate(json['used_at']),
      isBirthday: json['source'] == 'birthday',
      isSurprise: json['is_surprise'] as bool? ?? false,
    );
  }

  static RewardStatus _statusFromApi(String? status) {
    switch (status) {
      case 'used':
        return RewardStatus.used;
      case 'canceled':
        return RewardStatus.canceled;
      default:
        return RewardStatus.available;
    }
  }
}
