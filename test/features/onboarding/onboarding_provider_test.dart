import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('OnboardingNotifier — validation programme fidélité (step2/step3)', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('setStampsRequired clamp selon le mode stamps (3-50)', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);

      notifier.setStampsRequired(0);
      expect(container.read(onboardingNotifierProvider).stampsRequired, 3);

      notifier.setStampsRequired(999);
      expect(container.read(onboardingNotifierProvider).stampsRequired, 50);
    });

    test('setCashbackPercentage clamp entre 0.1 et 100', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setLoyaltyMode('cashback');

      notifier.setCashbackPercentage(0);
      expect(container.read(onboardingNotifierProvider).cashbackPercentage, 0.1);

      notifier.setCashbackPercentage(500);
      expect(container.read(onboardingNotifierProvider).cashbackPercentage, 100);
    });

    test('toLoyaltyProgramJson omet goal/rewards en mode cashback', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setLoyaltyMode('cashback');
      notifier.setCashbackPercentage(5);

      final json = container.read(onboardingNotifierProvider).toLoyaltyProgramJson();

      expect(json.containsKey('goal'), false);
      expect(json.containsKey('rewards'), false);
      expect(json['cashback_percentage'], 5.0);
    });

    test('setStampsRequired clamp selon le mode spend (50-1000000)', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setLoyaltyMode('spend');

      notifier.setStampsRequired(1);
      expect(container.read(onboardingNotifierProvider).stampsRequired, 50);
    });

    test('setRewardDescription supprime les espaces en trop', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);

      notifier.setRewardDescription('  1 café offert  ');

      expect(
        container.read(onboardingNotifierProvider).rewardDescription,
        '1 café offert',
      );
    });

    test('désactiver showReviewButton vide googleReviewUrl', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setShowReviewButton(true);
      notifier.setGoogleReviewUrl('https://g.page/test');
      expect(
        container.read(onboardingNotifierProvider).googleReviewUrl,
        'https://g.page/test',
      );

      notifier.setShowReviewButton(false);

      expect(container.read(onboardingNotifierProvider).googleReviewUrl, '');
    });

    test(
        'toLoyaltyProgramJson omet google_review_url si showReviewButton est faux',
        () {
      final notifier = container.read(onboardingNotifierProvider.notifier);
      // Le champ peut rester renseigné en mémoire (bascule du switch pendant
      // la saisie) sans que showReviewButton ne soit repassé à true : le
      // payload envoyé au backend ne doit jamais l'inclure dans ce cas.
      notifier.setGoogleReviewUrl('https://g.page/test');

      final json = container.read(onboardingNotifierProvider).toLoyaltyProgramJson();

      expect(json['google_review_url'], isNull);
    });

    test('colorSecondaryHex est dérivée de colorPrimary, pas un champ saisi', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);

      notifier.setColorPrimary(const Color(0xFF4F46E5));
      final hexA = container.read(onboardingNotifierProvider).colorSecondaryHex;

      notifier.setColorPrimary(const Color(0xFFE53935));
      final hexB = container.read(onboardingNotifierProvider).colorSecondaryHex;

      expect(hexA, isNot(equals(hexB)));
      expect(hexB, startsWith('#'));
    });
  });
}
