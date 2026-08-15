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
import 'package:miva_fid/features/client/widgets/shared/phone_input_with_country_picker.dart';

/// Formulaire d'inscription complet : Nom · Date de naissance · Téléphone → /wallet
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with FormErrorHandler {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneInputKey = GlobalKey<PhoneInputWithCountryPickerState>();
  final _phoneController = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Étape 1 de l'inscription : identité, téléphone, date de naissance.
  ///
  /// Le compte n'est pas encore créé ici. Les informations sont d'abord
  /// soumises à `POST /auth/validate-register-step1`, qui vérifie l'unicité du
  /// numéro et le fait passer par `FraudRiskService`. Échouer maintenant évite
  /// de faire choisir un mot de passe pour un numéro qui sera refusé.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fullPhone = _phoneInputKey.currentState?.fullPhoneNumber ??
        _phoneController.text.trim();

    ref.read(signupFlowProvider.notifier).startPhoneSignup(
          fullName: _fullNameController.text.trim(),
          phone: fullPhone,
          birthDate: _birthDate,
        );

    final t = AppLocalizations.of(context)!;
    final valid = await runGuarded(
      () => ref
          .read(authProvider.notifier)
          .validateRegisterStep1(ref.read(signupFlowProvider)),
      useOverlay: true,
      loadingMessage: t.authLoadingSignup,
    );

    if (!mounted || valid == null) return;

    if (valid) {
      context.push('/client/create-password');
    } else {
      handleError(
        ref.read(authProvider).lastError,
        context: ErrorContext.signup,
        formKey: _formKey,
      );
    }
  }

  void _goToLogin() {
    context.go('/client/auth');
  }

  Future<void> _continueWithSocial(AuthProvider provider) async {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.authSignupTitle, style: AppTextStyles.displayHero()),
                      const SizedBox(height: 20),
                      Text(t.editProfileFullName, style: AppTextStyles.label()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fullNameController,
                        keyboardType: TextInputType.name,
                        validator: fieldValidator(
                          'first_name',
                          requiredMessage: t.editProfileFullNameError,
                        ),
                        onChanged: (_) => clearFieldError('first_name'),
                        style: AppTextStyles.bodyMedium(),
                        decoration: InputDecoration(
                          hintText: t.editProfileFullNameHint,
                          hintStyle: AppTextStyles.bodyMedium(
                              color: AppColors.inkMuted(opacity: 0.4)),
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(t.editProfileBirthDate,
                          style: AppTextStyles.label()),
                      const SizedBox(height: 6),
                      AppDatePickerField(
                        value: _birthDate,
                        onChanged: (date) => setState(() => _birthDate = date),
                        validator: (_) => _birthDate == null
                            ? t.authBirthDateError
                            : fieldError('birthdate'),
                      ),
                      const SizedBox(height: 14),
                      Text(t.commonPhoneLabel, style: AppTextStyles.label()),
                      const SizedBox(height: 6),
                      PhoneInputWithCountryPicker(
                        key: _phoneInputKey,
                        controller: _phoneController,
                        validator: fieldValidator(
                          'phone',
                          requiredMessage: t.authPhoneRequiredError,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: t.authSignupButton,
                        onTap: isBusy ? null : _submit,
                      ),
                      const SizedBox(height: 18),
                      const OrDivider(),
                      const SizedBox(height: 18),
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
                      const SizedBox(height: 10),
                      AppButton(
                        label: t.authSignupApple,
                        variant: AppButtonVariant.outline,
                        icon: SimpleIcons.apple,
                        onTap: isBusy
                            ? null
                            : () => _continueWithSocial(AuthProvider.apple),
                      ),
                      const SizedBox(height: 20),
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
          },
        ),
      ),
    );
  }
}
