import 'package:flutter/material.dart';

/// Mécanique de fidélité d'une carte.
enum LoyaltyMechanic { stamps, points, spend, cashback, vip }

/// Palier VIP — Platinum réserve le Bordeaux profond.
enum VipTier { none, silver, gold, platinum }

class LoyaltyCard {
  final String id;
  final String restaurantName;
  final String restaurantCategory;
  final LoyaltyMechanic mechanic;

  /// Couleur de doublure désaturée empruntée à l'identité du restaurant.
  final Color liningColor;

  /// Couleur secondaire du dégradé choisie par le marchand (`color_secondary`).
  /// Absente sur les anciennes cartes créées avant son introduction — dans ce
  /// cas [liningColor] seule pilote un dégradé dérivé automatiquement.
  final Color? secondaryColor;

  /// `linear` ou `radial` — style de dégradé choisi par le marchand.
  final String gradientType;

  /// `none`, `lines`, `waves` ou `dots` — motif de fond choisi par le marchand.
  final String decorationPattern;

  /// Logo du commerce, tel que configuré côté marchand.
  final String? logoUrl;

  /// Style de tampon choisi par le marchand : `check`, `icon` ou `emoji`.
  final String stampDesignType;

  /// Emoji du tampon quand [stampDesignType] vaut `emoji`.
  final String stampEmoji;

  /// Clé d'icône du tampon quand [stampDesignType] vaut `icon`.
  final String stampIcon;

  /// Tampons : progression actuelle / objectif.
  final int stampsCurrent;
  final int stampsGoal;

  /// Points : solde.
  final int pointsBalance;

  /// Cashback : solde en FCFA.
  final int cashbackBalanceFcfa;

  /// VIP : palier actuel.
  final VipTier vipTier;
  final double vipProgressToNextTier; // 0.0 à 1.0

  /// Pourcentage calculé côté serveur (0-100) : progression du cycle actuel
  /// pour Tampons/Achats, progression vers le niveau suivant pour Cashback
  /// (qui n'a pas de cycle). Jamais recalculé localement.
  final int percent;

  /// Niveau de fidélité (Bronze/Argent/Or...), indépendant des cycles de
  /// récompense — ne redescend jamais à un reset de cycle. `null` tant que
  /// le programme n'a pas encore été chargé/calculé côté serveur.
  final String? levelName;
  final int? levelPercentToNext;
  final bool isMaxLevel;

  final String fallbackId; // ex. "SUN-28392"
  final String welcomeOffer;

  const LoyaltyCard({
    required this.id,
    required this.restaurantName,
    required this.restaurantCategory,
    required this.mechanic,
    required this.liningColor,
    this.secondaryColor,
    this.gradientType = 'linear',
    this.decorationPattern = 'none',
    this.logoUrl,
    this.stampDesignType = 'check',
    this.stampEmoji = '✨',
    this.stampIcon = 'check_rounded',
    this.stampsCurrent = 0,
    this.stampsGoal = 8,
    this.pointsBalance = 0,
    this.cashbackBalanceFcfa = 0,
    this.vipTier = VipTier.none,
    this.vipProgressToNextTier = 0,
    this.percent = 0,
    this.levelName,
    this.levelPercentToNext,
    this.isMaxLevel = false,
    required this.fallbackId,
    this.welcomeOffer = '',
  });

  /// Construit une carte réelle depuis `POST/GET /loyalty-cards/*`
  /// (`{card: {..., restaurant: {...}, loyalty_program: {...}}}`).
  factory LoyaltyCard.fromApi(Map<String, dynamic> json) {
    final restaurant = json['restaurant'] as Map<String, dynamic>? ?? {};
    final program = json['loyalty_program'] as Map<String, dynamic>? ?? {};
    final config = program['config'] as Map<String, dynamic>? ?? {};
    final progress = json['progress'] as Map<String, dynamic>? ?? {};
    final level = json['level'] as Map<String, dynamic>?;

    return LoyaltyCard(
      id: json['id'].toString(),
      restaurantName: restaurant['name'] as String? ?? '',
      restaurantCategory: restaurant['category'] as String? ?? '',
      mechanic: _mechanicFromType(program['type'] as String?),
      liningColor: _colorFromHex(config['color_primary'] as String?)!,
      secondaryColor: _colorFromHex(config['color_secondary'] as String?,
          fallback: null),
      gradientType: config['card_gradient_type'] as String? ?? 'linear',
      decorationPattern: config['card_decoration_pattern'] as String? ?? 'none',
      logoUrl: (config['logo_url'] ?? restaurant['logo_url']) as String?,
      stampDesignType: config['stamp_design_type'] as String? ?? 'check',
      stampEmoji: config['stamp_emoji'] as String? ?? '✨',
      stampIcon: config['stamp_icon'] as String? ?? 'check_rounded',
      stampsCurrent: progress['stamps_current'] as int? ?? 0,
      stampsGoal: json['goal'] as int? ?? config['goal'] as int? ?? 8,
      pointsBalance: progress['stamps_current'] as int? ?? 0,
      cashbackBalanceFcfa:
          double.tryParse(json['cashback_balance_fcfa']?.toString() ?? '')
                  ?.round() ??
              0,
      percent: json['percent'] as int? ?? 0,
      levelName: level?['name'] as String?,
      levelPercentToNext: level?['percent_to_next'] as int?,
      isMaxLevel: level?['is_max_level'] as bool? ?? false,
      fallbackId: json['card_code'] as String? ?? '',
    );
  }

  LoyaltyCard copyWith({
    int? stampsCurrent,
    int? stampsGoal,
    int? pointsBalance,
    int? cashbackBalanceFcfa,
    int? percent,
    String? levelName,
    int? levelPercentToNext,
    bool? isMaxLevel,
  }) {
    return LoyaltyCard(
      id: id,
      restaurantName: restaurantName,
      restaurantCategory: restaurantCategory,
      mechanic: mechanic,
      liningColor: liningColor,
      secondaryColor: secondaryColor,
      gradientType: gradientType,
      decorationPattern: decorationPattern,
      logoUrl: logoUrl,
      stampDesignType: stampDesignType,
      stampEmoji: stampEmoji,
      stampIcon: stampIcon,
      stampsCurrent: stampsCurrent ?? this.stampsCurrent,
      stampsGoal: stampsGoal ?? this.stampsGoal,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      cashbackBalanceFcfa: cashbackBalanceFcfa ?? this.cashbackBalanceFcfa,
      vipTier: vipTier,
      vipProgressToNextTier: vipProgressToNextTier,
      percent: percent ?? this.percent,
      levelName: levelName ?? this.levelName,
      levelPercentToNext: levelPercentToNext ?? this.levelPercentToNext,
      isMaxLevel: isMaxLevel ?? this.isMaxLevel,
      fallbackId: fallbackId,
      welcomeOffer: welcomeOffer,
    );
  }

  /// Applique le payload `LoyaltyCardUpdated::broadcastWith()` (Reverb) — la
  /// même donnée `stamps_current` alimente `stampsCurrent`/`pointsBalance`,
  /// comme dans `fromApi` (voir `_mechanicFromType`, mode "Achat" inclus).
  LoyaltyCard applyRealtimeUpdate(Map<String, dynamic> payload) {
    final progress = payload['progress'] as Map<String, dynamic>? ?? {};
    final current = progress['stamps_current'] as int? ?? stampsCurrent;
    final level = payload['level'] as Map<String, dynamic>?;
    return copyWith(
      stampsCurrent: current,
      // Corrige le bug où `goal` ne se rafraîchissait qu'au fetch initial :
      // le payload temps réel porte désormais les mêmes champs calculés.
      stampsGoal: payload['goal'] as int?,
      pointsBalance: current,
      cashbackBalanceFcfa:
          double.tryParse(payload['cashback_balance_fcfa']?.toString() ?? '')
              ?.round(),
      percent: payload['percent'] as int?,
      levelName: level?['name'] as String?,
      levelPercentToNext: level?['percent_to_next'] as int?,
      isMaxLevel: level?['is_max_level'] as bool?,
    );
  }

  static LoyaltyMechanic _mechanicFromType(String? type) {
    switch (type) {
      case 'points':
        return LoyaltyMechanic.points;
      // Le mode "Achat" (`spend`) accumule le même compteur générique que
      // "Points" côté backend (`stamps_current`, converti depuis le montant
      // FCFA au taux `fcfa_per_point`) — même donnée que `points`, mais un
      // rendu distinct (objectif visible) car contrairement à "Points" ce
      // mode reste borné par `goal` comme les tampons.
      case 'spend':
        return LoyaltyMechanic.spend;
      default:
        return LoyaltyMechanic.stamps;
    }
  }

  static Color? _colorFromHex(String? hex,
      {Color? fallback = const Color(0xFF4F46E5)}) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  /// Résumé mono affiché sur la carte dans le wallet.
  String get quickStat {
    switch (mechanic) {
      case LoyaltyMechanic.stamps:
        return '$stampsCurrent / $stampsGoal SCEAUX';
      case LoyaltyMechanic.points:
        return '$pointsBalance PTS';
      case LoyaltyMechanic.spend:
        return '$pointsBalance / $stampsGoal PTS';
      case LoyaltyMechanic.cashback:
        return '$cashbackBalanceFcfa FCFA';
      case LoyaltyMechanic.vip:
        return vipTier.label.toUpperCase();
    }
  }
}

extension VipTierLabel on VipTier {
  String get label {
    switch (this) {
      case VipTier.none:
        return 'Membre';
      case VipTier.silver:
        return 'Silver';
      case VipTier.gold:
        return 'Gold';
      case VipTier.platinum:
        return 'Platinum';
    }
  }
}
