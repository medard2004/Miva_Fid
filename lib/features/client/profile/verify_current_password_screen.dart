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
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/features/client/widgets/shared/password_input.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Première étape du changement de mot de passe : vérification du mot de passe actuel.
class VerifyCurrentPasswordScreen extends ConsumerStatefulWidget {
  const VerifyCurrentPasswordScreen({super.key});

  @override
  ConsumerState<VerifyCurrentPasswordScreen> createState() =>
      _VerifyCurrentPasswordScreenState();
}

class _VerifyCurrentPasswordScreenState
    extends ConsumerState<VerifyCurrentPasswordScreen> with FormErrorHandler {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context)!;
    final password = _passwordController.text;

    final valid = await runGuarded(
      () => ref.read(authProvider.notifier).verifyPassword(password),
      useOverlay: true,
      loadingMessage: t.changePasswordVerifying,
    );

    if (!mounted || valid == null) return;

    if (valid) {
      context.push('/client/profile/set-new-password', extra: password);
      return;
    }

    final error = ref.read(authProvider).lastError;
    if (error != null) {
      handleError(error,
          context: ErrorContext.verifyPassword, formKey: _formKey);
    } else {
      showErrorToast(ErrorMessages.passwordCurrentIncorrect);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: t.changePasswordTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    t.changePasswordTitle,
                    style: AppTextStyles.displayMedium().copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    t.changePasswordVerifySubtitle,
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.65),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.changePasswordCurrentLabel,
                        style: AppTextStyles.label().copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      PasswordInput(
                        controller: _passwordController,
                        obscure: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onToggle: () => setState(() => _obscure = !_obscure),
                        onSubmitted: (_) => isBusy ? null : _submit(),
                        onChanged: (_) => clearFieldError('current_password'),
                        validator: fieldValidator(
                          'current_password',
                          requiredMessage: ErrorMessages.fieldRequired,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AppTapScale(
                          onTap: () => context.push('/client/forgot-password'),
                          scaleDown: 0.95,
                          child: Text(
                            t.authForgotPasswordLink,
                            style: AppTextStyles.bodySmall(color: AppColors.primary)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: t.changePasswordContinue,
                  fullWidth: true,
                  height: 50,
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
