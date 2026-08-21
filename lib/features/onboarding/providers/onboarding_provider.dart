import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../merchant/models/restaurant_account.dart';
import '../../merchant/providers/merchant_auth_provider.dart';
import '../models/program_tier.dart';
import '../utils/card_colors.dart';

part 'onboarding_provider.g.dart';

class OnboardingState {
  const OnboardingState({
    this.phone = '',
    this.commerceName = '',
    this.commerceType = '',
    this.address = '',
    this.city = '',
    this.country = '',
    this.description = '',
    this.logoUrl,
    this.colorPrimary = const Color(0xFF4F46E5),
    this.colorSecondary = const Color(0xFF3730A3),
    this.tiers = const [ProgramTier(goal: 10, rewardDescription: '')],
    this.loyaltyMode = 'stamps',
    this.fcfaPerPoint = 100,
    this.cashbackPercentage = 5,
    this.cashbackRedeemCapPercent = 50,
    this.cashbackExpiryDays,
    this.showReviewButton = false,
    this.googleReviewUrl = '',
    this.stampDesignType = 'icon',
    this.stampEmoji = '✨',
    this.stampIcon = 'check_rounded',
    this.cardDecorationPattern = 'none',
    this.cardGradientType = 'linear',
    this.whatsapp = '',
    this.instagram = '',
    this.facebook = '',
    this.tiktok = '',
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.error,
  });

  final String phone;
  final String commerceName;
  final String commerceType;
  final String address;
  final String city;
  final String country;
  final String description;
  final String? logoUrl;
  final Color colorPrimary;
  final Color colorSecondary;
  final List<ProgramTier> tiers;
  final String loyaltyMode;
  /// Mode "Achat" : nombre de FCFA dépensés pour créditer 1 point.
  final int fcfaPerPoint;
  /// Mode "Cashback" : pourcentage de chaque achat crédité en solde.
  final double cashbackPercentage;
  /// Mode "Cashback" : part maximale (%) d'un achat réglable avec le solde
  /// cashback — `null` = pas de plafond.
  final int? cashbackRedeemCapPercent;
  /// Mode "Cashback" : le solde expire après ce nombre de jours sans
  /// nouveau crédit — `null` = pas d'expiration.
  final int? cashbackExpiryDays;
  final bool showReviewButton;
  final String googleReviewUrl;
  final String stampDesignType;
  final String stampEmoji;
  final String stampIcon;
  final String cardDecorationPattern;
  final String cardGradientType;
  final String whatsapp;
  final String instagram;
  final String facebook;
  final String tiktok;
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final String? error;

  int get stampsRequired => tiers.isNotEmpty ? tiers.first.goal : 10;
  String get rewardDescription => tiers.isNotEmpty ? tiers.first.rewardDescription : '';

  String get colorPrimaryHex =>
      '#${(colorPrimary.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  /// Dérivée de `colorPrimary` (pas de second sélecteur dans l'UI) — évite la
  /// divergence entre ce que la preview affiche et ce qui part au backend.
  String get colorSecondaryHex {
    final c = deriveSecondaryColor(colorPrimary);
    return '#${(c.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  OnboardingState copyWith({
    String? phone,
    String? commerceName,
    String? commerceType,
    String? address,
    String? city,
    String? country,
    String? description,
    String? logoUrl,
    Color? colorPrimary,
    Color? colorSecondary,
    List<ProgramTier>? tiers,
    String? loyaltyMode,
    int? fcfaPerPoint,
    double? cashbackPercentage,
    int? cashbackRedeemCapPercent,
    bool clearCashbackRedeemCap = false,
    int? cashbackExpiryDays,
    bool clearCashbackExpiryDays = false,
    bool? showReviewButton,
    String? googleReviewUrl,
    String? stampDesignType,
    String? stampEmoji,
    String? stampIcon,
    String? cardDecorationPattern,
    String? cardGradientType,
    String? whatsapp,
    String? instagram,
    String? facebook,
    String? tiktok,
    double? latitude,
    double? longitude,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      phone: phone ?? this.phone,
      commerceName: commerceName ?? this.commerceName,
      commerceType: commerceType ?? this.commerceType,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorSecondary: colorSecondary ?? this.colorSecondary,
      tiers: tiers ?? this.tiers,
      loyaltyMode: loyaltyMode ?? this.loyaltyMode,
      fcfaPerPoint: fcfaPerPoint ?? this.fcfaPerPoint,
      cashbackPercentage: cashbackPercentage ?? this.cashbackPercentage,
      cashbackRedeemCapPercent: clearCashbackRedeemCap
          ? null
          : (cashbackRedeemCapPercent ?? this.cashbackRedeemCapPercent),
      cashbackExpiryDays: clearCashbackExpiryDays
          ? null
          : (cashbackExpiryDays ?? this.cashbackExpiryDays),
      showReviewButton: showReviewButton ?? this.showReviewButton,
      googleReviewUrl: googleReviewUrl ?? this.googleReviewUrl,
      stampDesignType: stampDesignType ?? this.stampDesignType,
      stampEmoji: stampEmoji ?? this.stampEmoji,
      stampIcon: stampIcon ?? this.stampIcon,
      cardDecorationPattern: cardDecorationPattern ?? this.cardDecorationPattern,
      cardGradientType: cardGradientType ?? this.cardGradientType,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Payload envoyé à `POST /loyalty-programs` (step2/3 + review).
  bool get isCashback => loyaltyMode == 'cashback';

  Map<String, dynamic> toLoyaltyProgramJson() {
    return {
      'mode': loyaltyMode,
      if (!isCashback) 'tiers': tiers.map((t) => t.toJson()).toList(),
      'show_review_button': showReviewButton,
      'google_review_url':
          (showReviewButton && googleReviewUrl.isNotEmpty) ? googleReviewUrl : null,
      'color_primary': colorPrimaryHex,
      'color_secondary': colorSecondaryHex,
      'stamp_design_type': stampDesignType,
      'stamp_emoji': stampEmoji.isEmpty ? null : stampEmoji,
      'stamp_icon': stampIcon.isEmpty ? null : stampIcon,
      'card_decoration_pattern': cardDecorationPattern,
      'card_gradient_type': cardGradientType,
      'logo_url': logoUrl,
      if (loyaltyMode == 'spend') 'fcfa_per_point': fcfaPerPoint,
      if (isCashback) 'cashback_percentage': cashbackPercentage,
      if (isCashback && cashbackRedeemCapPercent != null)
        'cashback_redeem_cap_percent': cashbackRedeemCapPercent,
      if (isCashback && cashbackExpiryDays != null)
        'cashback_expiry_days': cashbackExpiryDays,
    };
  }

  /// Payload envoyé à `PUT /auth/merchant/profile` (step1, puis réutilisé
  /// tel quel par l'étape localisation avec latitude/longitude en plus).
  Map<String, dynamic> toBusinessInfoJson() {
    return {
      'name': commerceName,
      'category': commerceType,
      'phone': phone,
      'address': address.isEmpty ? null : address,
      'city': city.isEmpty ? null : city,
      'country': country.isEmpty ? null : country,
      'description': description.isEmpty ? null : description,
      'whatsapp': whatsapp.isEmpty ? null : whatsapp,
      'instagram': instagram.isEmpty ? null : instagram,
      'facebook': facebook.isEmpty ? null : facebook,
      'tiktok': tiktok.isEmpty ? null : tiktok,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  void setPhone(String v) => state = state.copyWith(phone: v);
  void setCommerceName(String v) => state = state.copyWith(commerceName: v);
  void setCommerceType(String v) => state = state.copyWith(commerceType: v);
  void setAddress(String v) => state = state.copyWith(address: v);
  void setCity(String v) => state = state.copyWith(city: v);
  void setCountry(String v) => state = state.copyWith(country: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setLogoUrl(String v) => state = state.copyWith(logoUrl: v);
  void setColorPrimary(Color c) => state = state.copyWith(colorPrimary: c);
  void setStampsRequired(int v) {
    final (min, max) = switch (state.loyaltyMode) {
      'stamps' => (3, 50),
      'spend' => (50, 1000000),
      _ => (1, 1000000),
    };
    final clampedGoal = v.clamp(min, max);
    if (state.tiers.isEmpty) {
      state = state.copyWith(tiers: [ProgramTier(goal: clampedGoal, rewardDescription: '')]);
    } else {
      final updated = List<ProgramTier>.from(state.tiers);
      updated[0] = updated[0].copyWith(goal: clampedGoal);
      state = state.copyWith(tiers: updated);
    }
  }

  void setTiers(List<ProgramTier> tiers) {
    state = state.copyWith(tiers: tiers);
  }

  void addTier([ProgramTier? tier]) {
    final list = List<ProgramTier>.from(state.tiers);
    if (tier != null) {
      list.add(tier);
    } else {
      final lastGoal = list.isNotEmpty ? list.last.goal : 10;
      final step = state.loyaltyMode == 'stamps' ? 5 : 500;
      list.add(ProgramTier(goal: lastGoal + step, rewardDescription: ''));
    }
    state = state.copyWith(tiers: list);
  }

  void removeTier(int index) {
    if (state.tiers.length <= 1) return;
    final list = List<ProgramTier>.from(state.tiers);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(tiers: list);
    }
  }

  void updateTier(int index, ProgramTier tier) {
    final list = List<ProgramTier>.from(state.tiers);
    if (index >= 0 && index < list.length) {
      list[index] = tier;
      state = state.copyWith(tiers: list);
    }
  }

  void setLoyaltyMode(String v) => state = state.copyWith(loyaltyMode: v);
  void setFcfaPerPoint(int v) =>
      state = state.copyWith(fcfaPerPoint: v.clamp(1, 1000000));
  void setCashbackPercentage(double v) =>
      state = state.copyWith(cashbackPercentage: v.clamp(0.1, 100));
  void setCashbackRedeemCapPercent(int? v) {
    if (v == null) {
      state = state.copyWith(clearCashbackRedeemCap: true);
    } else {
      state = state.copyWith(cashbackRedeemCapPercent: v.clamp(1, 100));
    }
  }
  void setCashbackExpiryDays(int? v) {
    if (v == null) {
      state = state.copyWith(clearCashbackExpiryDays: true);
    } else {
      state = state.copyWith(cashbackExpiryDays: v.clamp(1, 3650));
    }
  }
  void setRewardDescription(String v) {
    final trimmed = v.trim();
    if (state.tiers.isEmpty) {
      state = state.copyWith(tiers: [ProgramTier(goal: 10, rewardDescription: trimmed)]);
    } else {
      final updated = List<ProgramTier>.from(state.tiers);
      updated[0] = updated[0].copyWith(rewardDescription: trimmed);
      state = state.copyWith(tiers: updated);
    }
  }

  void setShowReviewButton(bool v) => state = state.copyWith(
        showReviewButton: v,
        googleReviewUrl: v ? state.googleReviewUrl : '',
      );
  void setGoogleReviewUrl(String v) =>
      state = state.copyWith(googleReviewUrl: v.trim());
  void setStampDesignType(String v) =>
      state = state.copyWith(stampDesignType: v);
  void setStampEmoji(String v) =>
      state = state.copyWith(stampEmoji: v);
  void setStampIcon(String v) =>
      state = state.copyWith(stampIcon: v);
  void setCardDecorationPattern(String v) =>
      state = state.copyWith(cardDecorationPattern: v);
  void setCardGradientType(String v) =>
      state = state.copyWith(cardGradientType: v);
  void setWhatsapp(String v) => state = state.copyWith(whatsapp: v);
  void setInstagram(String v) => state = state.copyWith(instagram: v);
  void setFacebook(String v) => state = state.copyWith(facebook: v);
  void setTiktok(String v) => state = state.copyWith(tiktok: v);
  void setLocation(double lat, double lng) =>
      state = state.copyWith(latitude: lat, longitude: lng);

  /// Crée le compte marchand (email + password) via l'API Laravel.
  Future<bool> registerUser(String email, String password) async {
    state = state.copyWith(isLoading: true);
    final ok = await ref.read(merchantAuthProvider.notifier).register(email, password);
    state = state.copyWith(isLoading: false);
    return ok;
  }

  /// Envoie les infos business (step1) au compte marchand déjà authentifié.
  Future<bool> submitBusinessInfo() async {
    state = state.copyWith(isLoading: true);
    final ok = await ref
        .read(merchantAuthProvider.notifier)
        .updateBusinessInfo(state.toBusinessInfoJson());
    state = state.copyWith(isLoading: false);
    return ok;
  }

  /// Envoie la position choisie (étape localisation) — même transport que
  /// `submitBusinessInfo()`, `toBusinessInfoJson()` inclut déjà lat/lng.
  Future<bool> submitLocation() async {
    state = state.copyWith(isLoading: true);
    final ok = await ref
        .read(merchantAuthProvider.notifier)
        .updateBusinessInfo(state.toBusinessInfoJson());
    state = state.copyWith(isLoading: false);
    return ok;
  }

  /// Envoie le programme de fidélité (step2/3) puis recharge le compte —
  /// `POST /loyalty-programs` ne renvoie pas le restaurant, contrairement à
  /// `submitBusinessInfo`/`submitLocation`.
  Future<bool> submitLoyaltyProgram() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(loyaltyProgramServiceProvider)
          .save(state.toLoyaltyProgramJson());
      final ok = await ref.read(merchantAuthProvider.notifier).refreshFromApi();
      state = state.copyWith(isLoading: false);
      return ok;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void reset() => state = const OnboardingState();

  /// Repart d'un état propre, prérempli avec ce que le compte contient déjà.
  ///
  /// Appelé après une inscription ou une connexion marchande : sans ça, un
  /// second parcours dans la même session rejouerait les valeurs du premier,
  /// et un marchand qui reprend un onboarding inachevé retrouverait des
  /// champs vides alors que le serveur a déjà ses informations.
  void hydrateFrom(RestaurantAccount? restaurant) {
    if (restaurant == null) {
      reset();
      return;
    }

    final config = restaurant.loyaltyConfig;
    Color? color(String key) {
      final hex = config[key]?.toString().replaceAll('#', '');
      if (hex == null || hex.isEmpty) return null;
      final value = int.tryParse('FF$hex', radix: 16);
      return value == null ? null : Color(value);
    }

    String text(String? value) => value ?? '';

    List<ProgramTier> loadedTiers = [];
    if (config['tiers'] is List) {
      for (final item in config['tiers'] as List) {
        if (item is Map<String, dynamic>) {
          loadedTiers.add(ProgramTier.fromJson(item));
        } else if (item is Map) {
          loadedTiers.add(ProgramTier.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    if (loadedTiers.isEmpty) {
      loadedTiers = [
        ProgramTier(
          goal: (int.tryParse(config['goal']?.toString() ?? '') ?? 10).clamp(1, 1000000),
          rewardDescription: text(config['reward_description']?.toString()),
        ),
      ];
    }

    state = OnboardingState(
      phone: text(restaurant.phone),
      commerceName: text(restaurant.name),
      commerceType: text(restaurant.category),
      address: text(restaurant.address),
      city: text(restaurant.city),
      country: text(restaurant.country),
      description: text(restaurant.description),
      logoUrl: config['logo_url']?.toString() ?? restaurant.logoUrl,
      colorPrimary: color('color_primary') ?? const Color(0xFF4F46E5),
      colorSecondary: color('color_secondary') ?? const Color(0xFF3730A3),
      tiers: loadedTiers,
      loyaltyMode: restaurant.loyaltyType ?? 'stamps',
      fcfaPerPoint:
          int.tryParse(config['fcfa_per_point']?.toString() ?? '') ?? 100,
      cashbackPercentage:
          double.tryParse(config['cashback_percentage']?.toString() ?? '') ?? 5,
      cashbackRedeemCapPercent:
          int.tryParse(config['cashback_redeem_cap_percent']?.toString() ?? ''),
      cashbackExpiryDays:
          int.tryParse(config['cashback_expiry_days']?.toString() ?? ''),
      showReviewButton: config['show_review_button'] == true,
      googleReviewUrl: text(config['google_review_url']?.toString()),
      stampDesignType: config['stamp_design_type']?.toString() ?? 'icon',
      stampEmoji: config['stamp_emoji']?.toString() ?? '✨',
      stampIcon: config['stamp_icon']?.toString() ?? 'check_rounded',
      cardDecorationPattern:
          config['card_decoration_pattern']?.toString() ?? 'none',
      cardGradientType: config['card_gradient_type']?.toString() ?? 'linear',
      whatsapp: text(restaurant.whatsapp),
      instagram: text(restaurant.instagram),
      facebook: text(restaurant.facebook),
      tiktok: text(restaurant.tiktok),
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
    );
  }
}
