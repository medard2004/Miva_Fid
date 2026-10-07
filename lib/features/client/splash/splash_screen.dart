import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/app_startup_provider.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/shared/loading_dots.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';
import 'package:miva_fid/features/onboarding/providers/onboarding_provider.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Écran d'amorçage : attend la restauration de session avant de router.
///
/// Sans cette étape, l'app afficherait brièvement l'écran de connexion à un
/// utilisateur déjà authentifié, le temps que `GET /auth/me` réponde.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    // Filet de sécurité absolu : si pour une raison quelconque (réseau, timeout)
    // l'amorçage tarde, on ne laisse jamais l'utilisateur bloqué sur le splash.
    _fallbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_hasNavigated) {
        _performNavigation(ref.read(appStartupProvider).valueOrNull);
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _performNavigation(AppStartupState? state) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    final lastRole = state?.lastRole;
    final isClientAuth = ref.read(authProvider).isAuthenticated;
    final isMerchantAuth = ref.read(merchantAuthProvider).isAuthenticated;

    // 1. Si le dernier mode actif était 'merchant' et que le compte marchand est connecté
    if (lastRole == 'merchant' && isMerchantAuth) {
      final restaurant = ref.read(merchantAuthProvider).restaurant;
      ref.read(onboardingNotifierProvider.notifier).hydrateFrom(restaurant);
      context.go(switch ((
        restaurant?.hasLoyaltyProgram ?? false,
        restaurant?.hasLocation ?? false,
        restaurant?.hasBusinessInfo ?? false,
      )) {
        (true, _, _) => '/merchant/validate',
        (false, true, _) => '/auth/merchant/step2',
        (false, false, true) => '/auth/merchant/location',
        _ => '/auth/merchant/step1',
      });
      return;
    }

    // 2. Session client restaurée
    if (isClientAuth) {
      context.go('/client/wallet');
      return;
    }

    // 3. Session marchand restaurée (fallback)
    if (isMerchantAuth) {
      final restaurant = ref.read(merchantAuthProvider).restaurant;
      ref.read(onboardingNotifierProvider.notifier).hydrateFrom(restaurant);
      context.go(switch ((
        restaurant?.hasLoyaltyProgram ?? false,
        restaurant?.hasLocation ?? false,
        restaurant?.hasBusinessInfo ?? false,
      )) {
        (true, _, _) => '/merchant/validate',
        (false, true, _) => '/auth/merchant/step2',
        (false, false, true) => '/auth/merchant/location',
        _ => '/auth/merchant/step1',
      });
      return;
    }

    // 3. Onboarding et rôle déjà choisis par le passé
    if (state != null && state.hasSeenOnboarding) {
      if (state.lastRole == 'merchant') {
        context.go('/auth/merchant/auth');
        return;
      }
      context.go('/client/auth');
      return;
    }

    // 4. Par défaut : Onboarding client direct (sélection de rôle supprimée au premier lancement)
    context.go('/client/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    // Si l'état d'amorçage est déjà disponible
    final currentStartup = ref.read(appStartupProvider);
    if (currentStartup.hasValue || currentStartup.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasNavigated) {
          _performNavigation(currentStartup.valueOrNull);
        }
      });
    }

    // Écoute réactive des changements futurs
    ref.listen<AsyncValue<AppStartupState>>(
      appStartupProvider,
      (_, next) {
        next.when(
          data: (state) => _performNavigation(state),
          error: (_, __) => _performNavigation(null),
          loading: () {},
        );
      },
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_mivaFid.png',
              width: 104,
              height: 104,
            )
                .animate()
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.0, 1.0),
                  duration: 300.ms,
                  curve: Curves.easeOut,
                )
                .then(delay: 150.ms)
                .scale(
                  end: const Offset(0.94, 0.94),
                  duration: 260.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scale(
                  end: const Offset(1.0, 1.0),
                  duration: 260.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 32),
            const LoadingDots(),
            const SizedBox(height: 16),
            Text(
              t.splashLoading,
              style: AppTextStyles.bodySmall(
                  color: AppColors.inkMuted(opacity: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
