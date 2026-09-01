import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/errors/app_error.dart';
import 'package:miva_fid/core/errors/error_messages.dart';
import 'package:miva_fid/core/errors/form_error_handler.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/phone_input_with_country_picker.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Première étape de la réinitialisation : demander l'envoi d'un code.
///
/// L'identifiant peut être un numéro de téléphone ou une adresse e-mail — le
/// backend accepte les deux (`ForgotPasswordRequest`) et distingue l'un de
/// l'autre par la présence d'un `@`.
///
/// Note d'exploitation : aucune passerelle SMS n'est branchée côté serveur.
/// Le code est écrit dans `storage/logs/laravel.log`, et renvoyé dans la
/// réponse (`debug_otp`) quand `APP_DEBUG` est actif.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with FormErrorHandler {
  final _formKey = GlobalKey<FormState>();
  final _phoneInputKey = GlobalKey<PhoneInputWithCountryPickerState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _useEmail = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    // Les erreurs portent sur le champ qu'on quitte : les garder afficherait
    // un message sans rapport avec le champ désormais visible.
    clearAllFieldErrors();
    setState(() => _useEmail = !_useEmail);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final identifier = _useEmail
        ? _emailController.text.trim()
        : (_phoneInputKey.currentState?.fullPhoneNumber ??
            _phoneController.text.trim());

    final t = AppLocalizations.of(context)!;

    final sent = await runGuarded(
      () => ref.read(authProvider.notifier).forgotPassword(identifier),
      useOverlay: true,
      loadingMessage: t.forgotPasswordSending,
    );

    if (!mounted || sent == null) return;

    if (sent) {
      showSuccessToast(ErrorMessages.forgotCodeSent);
      context.push('/client/otp', extra: {'phone': identifier});
    } else {
      // Compte inexistant → sous le champ ; panne d'envoi → toast.
      handleError(
        ref.read(authProvider).lastError,
        context: ErrorContext.forgotPassword,
        formKey: _formKey,
      );
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Icon(
                    LucideIcons.arrowLeft,
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
                  t.forgotPasswordTitle,
                  style: AppTextStyles.authTitle(),
                ),
                const SizedBox(height: 8),
                Text(
                  _useEmail
                      ? t.forgotPasswordSubtitleEmail
                      : t.forgotPasswordSubtitle,
                  style: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.65)),
                ),
                const SizedBox(height: 24),
                if (_useEmail) ...[
                  Text(t.forgotPasswordEmailLabel,
                      style: AppTextStyles.label()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: AppTextStyles.bodyMedium(),
                    onChanged: (_) => clearFieldError('email'),
                    validator: fieldValidator(
                      'email',
                      requiredMessage: ErrorMessages.fieldRequired,
                      extra: (value) => value.contains('@') && value.contains('.')
                          ? null
                          : ErrorMessages.emailInvalid,
                    ),
                    decoration: InputDecoration(
                      hintText: t.forgotPasswordEmailHint,
                      hintStyle: AppTextStyles.bodyMedium(
                          color: AppColors.inkMuted(opacity: 0.35)),
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ] else ...[
                  Text(t.commonPhoneLabel, style: AppTextStyles.label()),
                  const SizedBox(height: 8),
                  PhoneInputWithCountryPicker(
                    key: _phoneInputKey,
                    controller: _phoneController,
                    validator: fieldValidator(
                      'phone',
                      requiredMessage: t.authPhoneRequiredError,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: AppTapScale(
                    onTap: _toggleMode,
                    scaleDown: 0.95,
                    child: Text(
                      _useEmail
                          ? t.forgotPasswordUsePhone
                          : t.forgotPasswordUseEmail,
                      style:
                          AppTextStyles.bodyMedium(color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: t.forgotPasswordButton,
                  onTap: isBusy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
