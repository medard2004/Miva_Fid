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
import 'package:miva_fid/features/client/widgets/shared/password_input.dart';
import 'package:miva_fid/features/client/widgets/shared/password_rules_checklist.dart';
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
                  t.resetPasswordTitle,
                  style: AppTextStyles.authTitle(),
                ),
                const SizedBox(height: 8),
                Text(
                  t.resetPasswordSubtitle,
                  style: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.65)),
                ),
                const SizedBox(height: 24),
                Text(t.authPasswordLabel, style: AppTextStyles.label()),
                const SizedBox(height: 8),
                PasswordInput(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onChanged: (_) {
                    clearFieldError('password');
                    setState(() {});
                  },
                  validator: fieldValidator(
                    'password',
                    requiredMessage: ErrorMessages.fieldRequired,
                    extra: (value) {
                      if (value.length < 8) {
                        return ErrorMessages.passwordTooShort;
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return ErrorMessages.passwordNeedsUppercase;
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return ErrorMessages.passwordNeedsDigit;
                      }
                      return null;
                    },
                  ),
                ),
                ClientPasswordRulesChecklist(password: _passwordController.text),
                const SizedBox(height: 16),
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
