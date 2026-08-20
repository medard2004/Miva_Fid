import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../models/loyalty_card_model.dart';
import 'clients_provider.dart';
import 'dashboard_stats_provider.dart' show dashboardStatsProvider;

part 'validate_provider.g.dart';

/// Résultat d'une validation (`POST /merchant/clients/{card}/stamps`) — le
/// détail complet, contrairement au simple compteur renvoyé auparavant :
/// l'écran de succès a besoin de savoir combien de points ont été
/// effectivement crédités et si la récompense vient de se débloquer.
class ValidationOutcome {
  const ValidationOutcome({
    required this.stampsCurrent,
    required this.pointsEarned,
    required this.rewardUnlocked,
    required this.message,
    this.cashbackEarned,
  });

  final int stampsCurrent;
  final int pointsEarned;
  final bool rewardUnlocked;
  final String message;
  /// Mode Cashback uniquement — montant FCFA crédité par cette validation.
  final double? cashbackEarned;
}

/// Récompense résolue depuis un QR scanné (`/merchant/rewards/lookup`).
class MerchantReward {
  const MerchantReward({
    required this.id,
    required this.title,
    required this.status,
    required this.isExpired,
    this.clientName,
  });

  final String id;
  final String title;
  final String status;
  final bool isExpired;
  final String? clientName;

  bool get isRedeemable => status == 'available' && !isExpired;

  factory MerchantReward.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    return MerchantReward(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      isExpired: json['is_expired'] as bool? ?? false,
      clientName: client?['name'] as String?,
    );
  }
}

/// Écran de validation : recherche d'un client du commerce et attribution
/// de tampons (`/merchant/clients/*`).
@riverpod
class ValidateNotifier extends _$ValidateNotifier {
  @override
  void build() {}

  /// Recherche par code de carte, `qr_token` ou identifiant public du
  /// client — le serveur accepte les trois et ne renvoie que des cartes du
  /// commerce authentifié.
  Future<LoyaltyCardModel?> lookupByCode(String code) async {
    final row = await ref.read(merchantDashboardServiceProvider).lookup(code);
    return row == null ? null : LoyaltyCardModel.fromJson(row);
  }

  /// Conservé pour les appels par identifiant client ; même endpoint.
  Future<LoyaltyCardModel?> lookupClient(String clientId) =>
      lookupByCode(clientId);

  /// Accorde un tampon (ou des points, en mode "Achat" via [amountFcfa]).
  /// Le déblocage de la récompense (remise à zéro + statut
  /// `reward_available`) est décidé côté serveur, qui seul connaît
  /// l'objectif du programme.
  Future<ValidationOutcome> addStamp(String cardId, {double? amountFcfa}) async {
    final result = await ref
        .read(merchantDashboardServiceProvider)
        .addStamp(cardId, amountFcfa: amountFcfa);

    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(clientsNotifierProvider);

    final card = result['client'] as Map<String, dynamic>?;
    return ValidationOutcome(
      stampsCurrent: card?['stamps_current'] as int? ?? 0,
      pointsEarned: result['points_earned'] as int? ?? 1,
      rewardUnlocked: result['reward_unlocked'] as bool? ?? false,
      message: result['message'] as String? ?? '',
      cashbackEarned: (result['cashback_earned'] as num?)?.toDouble(),
    );
  }

  /// Mode Cashback : utilise une partie du solde comme réduction.
  Future<ValidationOutcome> redeemCashback(
    String cardId, {
    required double amountFcfa,
    required double redeemAmountFcfa,
  }) async {
    final result = await ref.read(merchantDashboardServiceProvider).redeemCashback(
          cardId,
          amountFcfa: amountFcfa,
          redeemAmountFcfa: redeemAmountFcfa,
        );

    ref.invalidate(clientsNotifierProvider);

    final card = result['client'] as Map<String, dynamic>?;
    return ValidationOutcome(
      stampsCurrent: card?['stamps_current'] as int? ?? 0,
      pointsEarned: 0,
      rewardUnlocked: false,
      message: result['message'] as String? ?? '',
    );
  }

  /// Résout le jeton d'un QR de récompense scanné — `null` si aucune
  /// récompense du commerce ne correspond (jeton étranger ou invalide).
  Future<MerchantReward?> lookupReward(String token) async {
    final row = await ref.read(merchantDashboardServiceProvider).lookupReward(token);
    return row == null ? null : MerchantReward.fromJson(row);
  }

  Future<MerchantReward> redeemReward(String rewardId) async {
    final result = await ref.read(merchantDashboardServiceProvider).redeemReward(rewardId);
    return MerchantReward.fromJson(result['reward'] as Map<String, dynamic>);
  }

  Future<MerchantReward> cancelReward(String rewardId, {String? reason}) async {
    final result = await ref
        .read(merchantDashboardServiceProvider)
        .cancelReward(rewardId, reason: reason);
    return MerchantReward.fromJson(result['reward'] as Map<String, dynamic>);
  }
}
