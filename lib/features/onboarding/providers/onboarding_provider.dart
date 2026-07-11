import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'onboarding_provider.g.dart';

class OnboardingState {
  const OnboardingState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
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
    this.stampDesignType = 'check',
    this.stampEmoji = '✨',
    this.stampIcon = 'check_rounded',
    this.cardDecorationPattern = 'none',
    this.cardGradientType = 'linear',
    this.isLoading = false,
    this.error,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
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
  final bool isLoading;
  final String? error;

  String get fullName => '$firstName $lastName'.trim();
  String get colorPrimaryHex =>
      '#${(colorPrimary.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  String get colorSecondaryHex =>
      '#${(colorSecondary.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  OnboardingState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
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
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
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
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Map<String, dynamic> toMerchantJson(String userId) {
    return {
      'user_id': userId,
      'name': commerceName,
      'category': commerceType,
      'address': address,
      'description': description.isEmpty ? null : description,
      'phone': phone,
      'color_primary': colorPrimaryHex,
      'color_secondary': colorSecondaryHex,
      'stamps_required': stampsRequired,
      'loyalty_mode': loyaltyMode,
      'reward_description': rewardDescription,
      'show_review_button': showReviewButton,
      'google_review_url': googleReviewUrl.isEmpty ? null : googleReviewUrl,
      'stamp_design_type': stampDesignType,
      'stamp_emoji': stampEmoji,
      'stamp_icon': stampIcon,
      'card_decoration_pattern': cardDecorationPattern,
      'card_gradient_type': cardGradientType,
      'logo_url': logoUrl,
    };
  }
}

@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  void setFirstName(String v) => state = state.copyWith(firstName: v);
  void setLastName(String v) => state = state.copyWith(lastName: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPassword(String v) => state = state.copyWith(password: v);
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

  Future<bool> registerUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: state.email,
        password: state.password,
      );
      if (res.user == null) throw Exception('Inscription échouée');

      await Supabase.instance.client.from('users').insert({
        'id': res.user!.id,
        'name': state.fullName,
        'phone': state.phone,
        'role': 'merchant',
      });

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint("Signup error: $e");
      state = state.copyWith(isLoading: false);
      return true;
    }
  }

  void reset() => state = const OnboardingState();
}
