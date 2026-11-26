import 'package:flutter/gestures.dart';
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

/// Écran d'inscription client : uniquement via fournisseur OAuth (Google / Apple).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with FormErrorHandler {
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => context.push('/client/legal/terms');
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => context.push('/client/legal/privacy');

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _goToLogin() {
    context.go('/client/auth');
  }

  Future<void> _continueWithSocial(AuthProvider provider) async {
    if (!_acceptedTerms) {
      setState(() => _showTermsError = true);
      return;
    }

    final t = AppLocalizations.of(context)!;

    try {
      final result = await runGuarded(
        () async {
          final idToken = provider == AuthProvider.google
              ? await SocialAuthService.signInWithGoogle()
              : await SocialAuthService.signInWithApple();
          if (idToken == null) return null;
          // `action: 'signup'` autorise le backend à créer le compte ; en
          // mode 'login' il refuserait un profil social inconnu.
          return ref
              .read(authProvider.notifier)
              .socialLogin(provider, idToken, action: 'signup');
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

      ref
          .read(signupFlowProvider.notifier)
          .startSocialSignup(provider: provider);

      context.go(result.needsProfileCompletion
          ? '/client/complete-social-profile'
          : '/client/wallet');
    } catch (e) {
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
                    context.go('/client/auth');
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                t.authSignupTitle,
                style: AppTextStyles.authTitle(),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: t.authSignupGoogle,
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
                label: t.authSignupApple,
                variant: AppButtonVariant.outline,
                icon: SimpleIcons.apple,
                onTap: isBusy
                    ? null
                    : () => _continueWithSocial(AuthProvider.apple),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) => setState(() {
                        _acceptedTerms = value ?? false;
                        if (_acceptedTerms) _showTermsError = false;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() {
                        _acceptedTerms = !_acceptedTerms;
                        if (_acceptedTerms) _showTermsError = false;
                      }),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall(
                              color: AppColors.inkMuted(opacity: 0.55)),
                          children: [
                            TextSpan(text: t.authAcceptPrefix),
                            TextSpan(
                              text: t.authTermsLink,
                              style: AppTextStyles.bodySmall(
                                      color: AppColors.ink)
                                  .copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration:
                                          TextDecoration.underline),
                              recognizer: _termsTap,
                            ),
                            TextSpan(text: t.authAcceptAnd),
                            TextSpan(
                              text: t.authPrivacyLink,
                              style: AppTextStyles.bodySmall(
                                      color: AppColors.ink)
                                  .copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration:
                                          TextDecoration.underline),
                              recognizer: _privacyTap,
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showTermsError) ...[
                const SizedBox(height: 6),
                Text(
                  t.authTermsRequiredError,
                  style: AppTextStyles.bodySmall(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 28),
              Center(
                child: AppTapScale(
                  onTap: _goToLogin,
                  scaleDown: 0.95,
                  child: Text.rich(
                    TextSpan(
                      text: t.authHasAccountPrefix,
                      style: AppTextStyles.bodyMedium(
                          color: AppColors.inkMuted(opacity: 0.55)),
                      children: [
                        TextSpan(
                          text: t.profileSignIn,
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
