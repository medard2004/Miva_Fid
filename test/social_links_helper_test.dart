import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/utils/social_links_helper.dart';

void main() {
  group('SocialLinksHelper.normalize & buildUrl', () {
    test('Instagram accepte @pseudo, pseudo et URL complète avec paramètres', () {
      expect(SocialLinksHelper.normalize('instagram', '@chez_awa'), 'chez_awa');
      expect(
        SocialLinksHelper.normalize(
          'instagram',
          'https://www.instagram.com/chez_awa/?igsh=abc123',
        ),
        'chez_awa',
      );
      expect(
        SocialLinksHelper.buildUrl('instagram', '@chez_awa'),
        'https://instagram.com/chez_awa',
      );
    });

    test('TikTok accepte @pseudo et URL complète', () {
      expect(
        SocialLinksHelper.normalize(
          'tiktok',
          'https://www.tiktok.com/@boutique.lome?_t=8xyz',
        ),
        'boutique.lome',
      );
      expect(
        SocialLinksHelper.buildUrl('tiktok', 'boutique.lome'),
        'https://tiktok.com/@boutique.lome',
      );
    });

    test('X accepte x.com et twitter.com', () {
      expect(
        SocialLinksHelper.normalize('x', 'https://twitter.com/mivafid/'),
        'mivafid',
      );
      expect(
        SocialLinksHelper.buildUrl('x', '@mivafid'),
        'https://x.com/mivafid',
      );
    });

    test('Facebook accepte lien page, profile.php?id= et slug', () {
      expect(
        SocialLinksHelper.normalize(
          'facebook',
          'https://www.facebook.com/chez.awa.lome/?mibextid=ZbWKwL',
        ),
        'chez.awa.lome',
      );
      expect(
        SocialLinksHelper.normalize(
          'facebook',
          'https://www.facebook.com/profile.php?id=10008451234&mibextid=LQQJ4d',
        ),
        'profile.php?id=10008451234',
      );
    });

    test('WhatsApp normalise numéro et lien wa.me', () {
      expect(
        SocialLinksHelper.normalize('whatsapp', '+228 90 12 34 56'),
        '+22890123456',
      );
      expect(
        SocialLinksHelper.buildUrl('whatsapp', 'https://wa.me/22890123456'),
        'https://wa.me/22890123456',
      );
    });

    test('Site web ajoute https:// automatiquement', () {
      expect(
        SocialLinksHelper.normalize('website', 'moncommerce.tg'),
        'https://moncommerce.tg',
      );
    });
  });

  group('SocialLinksHelper.validate', () {
    test('rejette les noms libres avec espaces sur Facebook/Instagram/TikTok', () {
      expect(SocialLinksHelper.validate('facebook', 'Ma Boutique Lomé'), isNotNull);
      expect(SocialLinksHelper.validate('instagram', 'mon commerce'), isNotNull);
      expect(SocialLinksHelper.validate('tiktok', 'chez awa'), isNotNull);
    });

    test('rejette un numéro WhatsApp trop court ou alphabétique', () {
      expect(SocialLinksHelper.validate('whatsapp', '1234'), isNotNull);
      expect(SocialLinksHelper.validate('whatsapp', 'chez_awa'), isNotNull);
      expect(SocialLinksHelper.validate('whatsapp', '+228 90 12 34 56'), isNull);
    });

    test('rejette un site web sans domaine valide', () {
      expect(SocialLinksHelper.validate('website', 'moncommerce'), isNotNull);
      expect(SocialLinksHelper.validate('website', 'moncommerce.com'), isNull);
    });

    test('accepte les champs vides (facultatifs)', () {
      expect(SocialLinksHelper.validate('instagram', ''), isNull);
      expect(SocialLinksHelper.validate('whatsapp', '   '), isNull);
    });
  });
}
