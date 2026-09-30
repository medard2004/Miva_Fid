import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../core/cache/offline_cache_service.dart';
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
    this.source,
    this.isSurprise = false,
    this.token,
    this.clientName,
    this.clientPhone,
    this.expiresAt,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String status;
  final bool isExpired;
  final String? source;
  final bool isSurprise;

  /// Jeton QR renvoyé par le lookup — requis par le serveur pour valider
  /// la récompense (prouve que le QR a été scanné).
  final String? token;
  final String? clientName;
  final String? clientPhone;
  final DateTime? expiresAt;
  final DateTime? unlockedAt;

  bool get isRedeemable => status == 'available' && !isExpired;

  factory MerchantReward.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    return MerchantReward(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      isExpired: json['is_expired'] as bool? ?? false,
      source: json['source'] as String?,
      isSurprise: json['is_surprise'] as bool? ?? false,
      token: json['token'] as String?,
      clientName: client?['name'] as String?,
      clientPhone: client?['phone'] as String?,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      unlockedAt: json['unlocked_at'] != null ? DateTime.tryParse(json['unlocked_at'] as String) : null,
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
  /// commerce authentifié. Fallback automatique sur le cache hors ligne.
  Future<LoyaltyCardModel?> lookupByCode(String code) async {
    try {
      final row = await ref.read(merchantDashboardServiceProvider).lookup(code);
      return row == null ? null : LoyaltyCardModel.fromJson(row);
    } catch (e) {
      final local = await lookupOffline(code);
      if (local != null) return local;
      rethrow;
    }
  }

  /// Recherche une carte dans le cache local (clients du commerce)
  Future<LoyaltyCardModel?> lookupOffline(String code) async {
    try {
      final cached = await ref.read(offlineCacheServiceProvider).getMerchantClients();
      if (cached == null) return null;

      final items = (cached['items'] as List?)
              ?.map((i) => Map<String, dynamic>.from(i as Map))
              .toList() ??
          [];

      final cleanCode = code.trim();
      final upperCode = cleanCode.toUpperCase();
      final phoneDigits = cleanCode.replaceAll(RegExp(r'\D'), '');

      for (final item in items) {
        if (item['id']?.toString() == cleanCode ||
            item['card_code']?.toString().toUpperCase() == upperCode) {
          return LoyaltyCardModel.fromJson(item);
        }

        final client = item['client'] as Map<String, dynamic>?;
        if (client != null) {
          if (client['uuid']?.toString() == cleanCode ||
              client['id']?.toString() == cleanCode) {
            return LoyaltyCardModel.fromJson(item);
          }

          if (phoneDigits.length >= 6) {
            final clientPhone =
                client['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
            if (clientPhone.endsWith(phoneDigits) ||
                phoneDigits.endsWith(clientPhone)) {
              return LoyaltyCardModel.fromJson(item);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[validate_provider] Erreur recherche carte en cache par téléphone: $e');
    }
    return null;
  }

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

    ref.invalidate(dashboardStatsProvider);
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

  Future<MerchantReward> redeemReward(String rewardId, {required String token}) async {
    final result = await ref
        .read(merchantDashboardServiceProvider)
        .redeemReward(rewardId, token: token);
    _invalidateAfterMutation();
    return MerchantReward.fromJson(result['reward'] as Map<String, dynamic>);
  }

  Future<MerchantReward> cancelReward(String rewardId, {String? reason}) async {
    final result = await ref
        .read(merchantDashboardServiceProvider)
        .cancelReward(rewardId, reason: reason);
    _invalidateAfterMutation();
    return MerchantReward.fromJson(result['reward'] as Map<String, dynamic>);
  }

  void _invalidateAfterMutation() {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(clientsNotifierProvider);
  }
}
