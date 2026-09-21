class ProximitySettingsModel {
  final bool enabled;
  final int radiusMeters;
  final String title;
  final String message;
  final int cooldownHours;
  final bool isActive;
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final bool planAllowsGeolocation;

  const ProximitySettingsModel({
    required this.enabled,
    required this.radiusMeters,
    required this.title,
    required this.message,
    this.cooldownHours = 24,
    this.isActive = false,
    this.hasLocation = false,
    this.latitude,
    this.longitude,
    this.planAllowsGeolocation = true,
  });

  factory ProximitySettingsModel.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] is Map
        ? (json['settings'] as Map).cast<String, dynamic>()
        : json;

    return ProximitySettingsModel(
      enabled: settings['enabled'] == true,
      radiusMeters: (settings['radius_m'] as num?)?.toInt() ?? 500,
      title: settings['title'] as String? ?? 'Vous êtes tout près de nous !',
      message: settings['message'] as String? ??
          'Passez nous voir et profitez de vos avantages fidélité.',
      cooldownHours: (settings['cooldown_hours'] as num?)?.toInt() ?? 24,
      isActive: json['is_active'] == true,
      hasLocation: json['has_location'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      planAllowsGeolocation: json['plan_allows_geolocation'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'radius_m': radiusMeters,
        'title': title,
        'message': message,
      };

  ProximitySettingsModel copyWith({
    bool? enabled,
    int? radiusMeters,
    String? title,
    String? message,
    int? cooldownHours,
    bool? isActive,
    bool? hasLocation,
    double? latitude,
    double? longitude,
    bool? planAllowsGeolocation,
  }) {
    return ProximitySettingsModel(
      enabled: enabled ?? this.enabled,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      title: title ?? this.title,
      message: message ?? this.message,
      cooldownHours: cooldownHours ?? this.cooldownHours,
      isActive: isActive ?? this.isActive,
      hasLocation: hasLocation ?? this.hasLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      planAllowsGeolocation:
          planAllowsGeolocation ?? this.planAllowsGeolocation,
    );
  }
}
