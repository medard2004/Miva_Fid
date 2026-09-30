import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/models/advertisement_model.dart';

void main() {
  group('AdvertisementModel', () {
    test('fromJson parses complete payload correctly', () {
      final json = {
        'id': 42,
        'title': 'Offre Spéciale Été',
        'subtitle': 'PROMO',
        'description': 'Profitez de -20% sur tout le menu.',
        'image_url': 'https://example.com/banner.png',
        'link_url': 'https://example.com/promo',
        'order': 1,
        'is_active': true,
      };

      final ad = AdvertisementModel.fromJson(json);

      expect(ad.id, 42);
      expect(ad.title, 'Offre Spéciale Été');
      expect(ad.subtitle, 'PROMO');
      expect(ad.description, 'Profitez de -20% sur tout le menu.');
      expect(ad.imageUrl, 'https://example.com/banner.png');
      expect(ad.linkUrl, 'https://example.com/promo');
      expect(ad.order, 1);
      expect(ad.isActive, isTrue);
    });

    test('fromJson handles null / missing optional fields safely', () {
      final json = {
        'id': 10,
        'title': 'Annonce basique',
      };

      final ad = AdvertisementModel.fromJson(json);

      expect(ad.id, 10);
      expect(ad.title, 'Annonce basique');
      expect(ad.subtitle, isNull);
      expect(ad.description, isNull);
      expect(ad.imageUrl, isNull);
      expect(ad.linkUrl, isNull);
      expect(ad.order, 0);
      expect(ad.isActive, isTrue);
    });

    test('toJson serializes correctly', () {
      const ad = AdvertisementModel(
        id: 5,
        title: 'Titre test',
        subtitle: 'Sub',
        description: 'Desc',
        imageUrl: 'https://test.com/img.jpg',
        linkUrl: 'https://test.com/link',
        order: 3,
        isActive: false,
      );

      final json = ad.toJson();

      expect(json['id'], 5);
      expect(json['title'], 'Titre test');
      expect(json['subtitle'], 'Sub');
      expect(json['description'], 'Desc');
      expect(json['image_url'], 'https://test.com/img.jpg');
      expect(json['link_url'], 'https://test.com/link');
      expect(json['order'], 3);
      expect(json['is_active'], isFalse);
    });
  });
}
