import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Dernière étape de la réinitialisation : choix du nouveau mot de passe.
///
/// [identifier] et [resetToken] proviennent de l'écran OTP. Le serveur révoque
/// tous les tokens du client au passage : il faudra se reconnecter.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.identifier,
    required this.resetToken,
  });

  final String identifier;
  final String resetToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with FormErrorHandler {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context)!;

    final done = await runGuarded(
      () => ref.read(authProvider.notifier).resetPassword(
            widget.identifier,
            widget.resetToken,
            _passwordController.text,
          ),
      useOverlay: true,
      loadingMessage: t.resetPasswordLoading,
    );

    if (!mounted || done == null) return;

    if (done) {
      showSuccessToast(ErrorMessages.resetSuccess);
      // Tous les tokens ayant été révoqués côté serveur, on repart de l'écran
      // de connexion plutôt que d'une session qui ne vaut plus rien.
      context.go('/client/auth');
    } else {
      handleError(
        ref.read(authProvider).lastError,
        context: ErrorContext.resetPassword,
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
      appBar: AppDetailBar(title: t.resetPasswordTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.resetPasswordTitle, style: AppTextStyles.displayHero()),
                const SizedBox(height: 8),
                Text(
                  t.resetPasswordSubtitle,
                  style: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.65)),
                ),
                const SizedBox(height: 32),
                Text(t.authPasswordLabel, style: AppTextStyles.label()),
                const SizedBox(height: 8),
                PasswordInput(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onChanged: (_) => clearFieldError('password'),
                  validator: fieldValidator(
                    'password',
                    requiredMessage: ErrorMessages.fieldRequired,
                    extra: (value) => value.length < 8
                        ? ErrorMessages.passwordTooShort
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text(t.createPasswordConfirmLabel,
                    style: AppTextStyles.label()),
                const SizedBox(height: 8),
                PasswordInput(
                  controller: _confirmController,
                  obscure: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => isBusy ? null : _submit(),
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return ErrorMessages.fieldRequired;
                    }
                    if (value != _passwordController.text) {
                      return ErrorMessages.passwordMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: t.resetPasswordButton,
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
