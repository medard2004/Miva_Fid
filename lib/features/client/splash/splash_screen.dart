import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/app_startup_provider.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/shared/loading_dots.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';
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
            context.go(
              merchant.restaurant?.hasBusinessInfo ?? false
                  ? '/merchant'
                  : '/auth/merchant/step1',
            );
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
            Text('Miva-Fid', style: AppTextStyles.displayXL()),
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
