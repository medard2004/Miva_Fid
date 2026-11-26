import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:miva_fid/core/errors/app_error.dart';
import 'package:miva_fid/core/errors/form_error_handler.dart';
import 'package:miva_fid/core/services/social_auth_service.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/user.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';

/// Écran de connexion client : uniquement via fournisseur OAuth (Google / Apple).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with FormErrorHandler {

  Future<void> _continueWithSocial(AuthProvider provider) async {
    final t = AppLocalizations.of(context)!;

    try {
      final result = await runGuarded(
        () async {
          final idToken = provider == AuthProvider.google
              ? await SocialAuthService.signInWithGoogle()
              : await SocialAuthService.signInWithApple();
          // `null` = l'utilisateur a fermé la feuille du fournisseur.
          if (idToken == null) return null;
          return ref
              .read(authProvider.notifier)
              .socialLogin(provider, idToken, action: 'login');
        },
        useOverlay: true,
        loadingMessage: provider == AuthProvider.google
            ? t.authLoadingGoogle
            : t.authLoadingApple,
      );

      if (!mounted || result == null) return;

      if (!result.success) {
        handleError(
          ref.read(authProvider).lastError,
          context: ErrorContext.socialLogin,
        );
        return;
      }

      // Google et Apple ne fournissent pas de numéro de téléphone : sans lui,
      // le compte reste incomplet et ne peut pas porter de carte de fidélité.
      if (result.needsProfileCompletion) {
        ref
            .read(signupFlowProvider.notifier)
            .startSocialSignup(provider: provider);
        context.go('/client/complete-social-profile');
      } else {
        context.go('/client/wallet');
      }
    } catch (e) {
      // Une annulation utilisateur est absorbée en silence par handleError.
      if (mounted) handleError(e, context: ErrorContext.socialLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.ink,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/client/onboarding');
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                t.authLoginTitle,
                style: AppTextStyles.authTitle(),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: t.authContinueGoogle,
                variant: AppButtonVariant.outline,
                leading: SvgPicture.asset(
                    'assets/icons/google_logo.svg',
                    width: 18,
                    height: 18),
                onTap: isBusy
                    ? null
                    : () => _continueWithSocial(AuthProvider.google),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: t.authContinueApple,
                variant: AppButtonVariant.outline,
                icon: SimpleIcons.apple,
                onTap: isBusy
                    ? null
                    : () => _continueWithSocial(AuthProvider.apple),
              ),
              const SizedBox(height: 28),
              Center(
                child: AppTapScale(
                  onTap: () => context.push('/client/signup'),
                  scaleDown: 0.95,
                  child: Text.rich(
                    TextSpan(
                      text: t.authNoAccountPrefix,
                      style: AppTextStyles.bodyMedium(
                          color: AppColors.inkMuted(opacity: 0.55)),
                      children: [
                        TextSpan(
                          text: t.authSignUpLink,
                          style: AppTextStyles.bodyMedium(
                                  color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
            ),
          );
  }
}
