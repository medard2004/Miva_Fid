import 'package:flutter/material.dart';

class MerchantModel {
  const MerchantModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.address,
    this.slug,
    this.logoUrl,
    this.coverUrl,
    this.description,
    this.phone,
    this.whatsapp,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.hours,
    this.colorPrimary = '#4F46E5',
    this.colorSecondary = '#3730A3',
    this.loyaltyMode = 'stamps',
    this.stampsRequired = 10,
    this.pointsPer500Fcfa = 1,
    this.rewardDescription,
    this.rewardValueFcfa,
    this.googleReviewUrl,
    this.showReviewButton = false,
    this.plan = 'free',
    this.smsRemaining = 100,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String category;
  final String? address;
  final String? slug;
  final String? logoUrl;
  final String? coverUrl;
  final String? description;
  final String? phone;
  final String? whatsapp;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final Map<String, dynamic>? hours;
  final String colorPrimary;
  final String colorSecondary;
  final String loyaltyMode;
  final int stampsRequired;
  final int pointsPer500Fcfa;
  final String? rewardDescription;
  final int? rewardValueFcfa;
  final String? googleReviewUrl;
  final bool showReviewButton;
  final String plan;
  final int smsRemaining;
  final DateTime createdAt;

  String get firstName => name.split(' ').first;
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get primaryColor {
    try {
      final hex = colorPrimary.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  Color get secondaryColor {
    try {
      final hex = colorSecondary.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF3730A3);
    }
  }

  bool get isPro => plan == 'pro';

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      address: json['address'] as String?,
      slug: json['slug'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      tiktok: json['tiktok'] as String?,
      hours: json['hours'] as Map<String, dynamic>?,
      colorPrimary: json['color_primary'] as String? ?? '#4F46E5',
      colorSecondary: json['color_secondary'] as String? ?? '#3730A3',
      loyaltyMode: json['loyalty_mode'] as String? ?? 'stamps',
      stampsRequired: json['stamps_required'] as int? ?? 10,
      pointsPer500Fcfa: json['points_per_500fcfa'] as int? ?? 1,
      rewardDescription: json['reward_description'] as String?,
      rewardValueFcfa: json['reward_value_fcfa'] as int?,
      googleReviewUrl: json['google_review_url'] as String?,
      showReviewButton: json['show_review_button'] as bool? ?? false,
      plan: json['plan'] as String? ?? 'free',
      smsRemaining: json['sms_remaining'] as int? ?? 100,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'address': address,
      'slug': slug,
      'logo_url': logoUrl,
      'cover_url': coverUrl,
      'description': description,
      'phone': phone,
      'whatsapp': whatsapp,
      'instagram': instagram,
      'facebook': facebook,
      'tiktok': tiktok,
      'hours': hours,
      'color_primary': colorPrimary,
      'color_secondary': colorSecondary,
      'loyalty_mode': loyaltyMode,
      'stamps_required': stampsRequired,
      'points_per_500fcfa': pointsPer500Fcfa,
      'reward_description': rewardDescription,
      'reward_value_fcfa': rewardValueFcfa,
      'google_review_url': googleReviewUrl,
      'show_review_button': showReviewButton,
      'plan': plan,
      'sms_remaining': smsRemaining,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MerchantModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? address,
    String? slug,
    String? logoUrl,
    String? coverUrl,
    String? description,
    String? phone,
    String? whatsapp,
    String? instagram,
    String? facebook,
    String? tiktok,
    Map<String, dynamic>? hours,
    String? colorPrimary,
    String? colorSecondary,
    String? loyaltyMode,
    int? stampsRequired,
    int? pointsPer500Fcfa,
    String? rewardDescription,
    int? rewardValueFcfa,
    String? googleReviewUrl,
    bool? showReviewButton,
    String? plan,
    int? smsRemaining,
    DateTime? createdAt,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      slug: slug ?? this.slug,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      hours: hours ?? this.hours,
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorSecondary: colorSecondary ?? this.colorSecondary,
      loyaltyMode: loyaltyMode ?? this.loyaltyMode,
      stampsRequired: stampsRequired ?? this.stampsRequired,
      pointsPer500Fcfa: pointsPer500Fcfa ?? this.pointsPer500Fcfa,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      rewardValueFcfa: rewardValueFcfa ?? this.rewardValueFcfa,
      googleReviewUrl: googleReviewUrl ?? this.googleReviewUrl,
      showReviewButton: showReviewButton ?? this.showReviewButton,
      plan: plan ?? this.plan,
      smsRemaining: smsRemaining ?? this.smsRemaining,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
