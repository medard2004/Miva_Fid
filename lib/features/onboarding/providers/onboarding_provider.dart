import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../merchant/providers/merchant_auth_provider.dart';

part 'onboarding_provider.g.dart';

class OnboardingState {
  const OnboardingState({
    this.phone = '',
    this.commerceName = '',
    this.commerceType = '',
    this.address = '',
    this.description = '',
    this.logoUrl,
    this.colorPrimary = const Color(0xFF4F46E5),
    this.colorSecondary = const Color(0xFF3730A3),
    this.stampsRequired = 10,
    this.loyaltyMode = 'stamps',
    this.rewardDescription = '',
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
    this.isLoading = false,
    this.error,
  });

  final String phone;
  final String commerceName;
  final String commerceType;
  final String address;
  final String description;
  final String? logoUrl;
  final Color colorPrimary;
  final Color colorSecondary;
  final int stampsRequired;
  final String loyaltyMode;
  final String rewardDescription;
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
  final bool isLoading;
  final String? error;

  String get colorPrimaryHex =>
      '#${(colorPrimary.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  String get colorSecondaryHex =>
      '#${(colorSecondary.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  OnboardingState copyWith({
    String? phone,
    String? commerceName,
    String? commerceType,
    String? address,
    String? description,
    String? logoUrl,
    Color? colorPrimary,
    Color? colorSecondary,
    int? stampsRequired,
    String? loyaltyMode,
    String? rewardDescription,
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
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      phone: phone ?? this.phone,
      commerceName: commerceName ?? this.commerceName,
      commerceType: commerceType ?? this.commerceType,
      address: address ?? this.address,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorSecondary: colorSecondary ?? this.colorSecondary,
      stampsRequired: stampsRequired ?? this.stampsRequired,
      loyaltyMode: loyaltyMode ?? this.loyaltyMode,
      rewardDescription: rewardDescription ?? this.rewardDescription,
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
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Payload envoyé à `POST /loyalty-programs` (step2/3 + review).
  Map<String, dynamic> toLoyaltyProgramJson() {
    return {
      'mode': loyaltyMode,
      'goal': stampsRequired,
      'reward_description':
          rewardDescription.isEmpty ? null : rewardDescription,
      'show_review_button': showReviewButton,
      'google_review_url': googleReviewUrl.isEmpty ? null : googleReviewUrl,
      'color_primary': colorPrimaryHex,
      'color_secondary': colorSecondaryHex,
      'stamp_design_type': stampDesignType,
      'stamp_emoji': stampEmoji.isEmpty ? null : stampEmoji,
      'stamp_icon': stampIcon.isEmpty ? null : stampIcon,
      'card_decoration_pattern': cardDecorationPattern,
      'card_gradient_type': cardGradientType,
      'logo_url': logoUrl,
    };
  }

  /// Payload envoyé à `PUT /auth/merchant/profile` (step1).
  Map<String, dynamic> toBusinessInfoJson() {
    return {
      'name': commerceName,
      'category': commerceType,
      'phone': phone,
      'address': address.isEmpty ? null : address,
      'description': description.isEmpty ? null : description,
      'whatsapp': whatsapp.isEmpty ? null : whatsapp,
      'instagram': instagram.isEmpty ? null : instagram,
      'facebook': facebook.isEmpty ? null : facebook,
      'tiktok': tiktok.isEmpty ? null : tiktok,
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
  void setDescription(String v) => state = state.copyWith(description: v);
  void setLogoUrl(String v) => state = state.copyWith(logoUrl: v);
  void setColorPrimary(Color c) => state = state.copyWith(colorPrimary: c);
  void setColorSecondary(Color c) => state = state.copyWith(colorSecondary: c);
  void setStampsRequired(int v) => state = state.copyWith(stampsRequired: v);
  void setLoyaltyMode(String v) => state = state.copyWith(loyaltyMode: v);
  void setRewardDescription(String v) =>
      state = state.copyWith(rewardDescription: v);
  void setShowReviewButton(bool v) =>
      state = state.copyWith(showReviewButton: v);
  void setGoogleReviewUrl(String v) =>
      state = state.copyWith(googleReviewUrl: v);
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

  void reset() => state = const OnboardingState();
}
