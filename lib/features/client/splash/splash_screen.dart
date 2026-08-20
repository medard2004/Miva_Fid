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
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    ref.listen<AsyncValue<AppStartupState>>(appStartupProvider, (_, next) {
      next.whenOrNull(
        data: (state) {
          // Session restaurée : on court-circuite le choix de rôle.
          if (ref.read(authProvider).isAuthenticated) {
            context.go('/client/wallet');
            return;
          }
          final merchant = ref.read(merchantAuthProvider);
          if (merchant.isAuthenticated) {
            final restaurant = merchant.restaurant;
            // Reprise d'une session déjà authentifiée sans passer par l'écran
            // de connexion (donc sans son propre appel à `hydrateFrom`) :
            // sans ceci, `OnboardingState` repart vide et l'étape localisation
            // (ou la revue) affiche des champs vierges malgré des données déjà
            // enregistrées côté serveur.
            ref.read(onboardingNotifierProvider.notifier).hydrateFrom(restaurant);
            context.go(switch ((
              restaurant?.hasLoyaltyProgram ?? false,
              restaurant?.hasLocation ?? false,
              restaurant?.hasBusinessInfo ?? false,
            )) {
              (true, _, _) => '/merchant',
              (false, true, _) => '/auth/merchant/step2',
              (false, false, true) => '/auth/merchant/location',
              _ => '/auth/merchant/step1',
            });
            return;
          }
          // Onboarding et rôle déjà vus : on saute directement à l'écran de
          // connexion du rôle mémorisé, plutôt que de tout remontrer.
          if (state.hasSeenOnboarding && state.lastRole == 'client') {
            context.go('/client/auth');
            return;
          }
          if (state.hasSeenOnboarding && state.lastRole == 'merchant') {
            context.go('/auth/merchant/auth');
            return;
          }
          context.go('/role-select');
        },
        // L'amorçage avale déjà ses erreurs (token refusé, backend absent) :
        // ce cas ne se produit qu'en cas de défaillance inattendue, et repart
        // sur le parcours normal plutôt que de bloquer l'app.
        error: (_, __) => context.go('/role-select'),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Séquence d'entrée façon Pinterest (portée depuis le design) :
            // apparition à taille normale puis léger effet de respiration.
            // Contrairement à l'écran design d'origine, pas d'envol/fondu de
            // sortie ici — la navigation réelle est pilotée par
            // `appStartupProvider` ci-dessus, pas par un minuteur fixe.
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
