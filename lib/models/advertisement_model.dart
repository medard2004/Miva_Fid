class AdvertisementModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;
  final int order;
  final bool isActive;

  const AdvertisementModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.linkUrl,
    this.order = 0,
    this.isActive = true,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      linkUrl: json['link_url'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'order': order,
      'is_active': isActive,
    };
  }
}
