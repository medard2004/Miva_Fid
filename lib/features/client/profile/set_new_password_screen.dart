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
import 'package:miva_fid/features/client/widgets/shared/password_rules_checklist.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Seconde étape du changement de mot de passe.
///
/// [currentPassword] a été validé par l'écran précédent ; l'API le redemande
/// à l'écriture (`PUT /auth/change-password`) pour ne pas se fier au seul
/// parcours côté client.
class SetNewPasswordScreen extends ConsumerStatefulWidget {
  const SetNewPasswordScreen({super.key, required this.currentPassword});

  final String currentPassword;

  @override
  ConsumerState<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends ConsumerState<SetNewPasswordScreen>
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

  String get _password => _passwordController.text;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context)!;

    final done = await runGuarded(
      () => ref
          .read(authProvider.notifier)
          .changePassword(widget.currentPassword, _password),
      useOverlay: true,
      loadingMessage: t.changePasswordSaving,
    );

    if (!mounted || done == null) return;

    if (done) {
      showSuccessToast(ErrorMessages.passwordChangeSuccess);
      // Deux niveaux à dépiler : cet écran et la vérification qui l'a poussé,
      // pour revenir au profil et non à la saisie du mot de passe actuel.
      context
        ..pop()
        ..pop();
    } else {
      handleError(
        ref.read(authProvider).lastError,
        context: ErrorContext.changePassword,
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
      appBar: AppDetailBar(title: t.changePasswordNewTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.changePasswordNewTitle,
                    style: AppTextStyles.displayHero()),
                const SizedBox(height: 10),
                Text(
                  t.changePasswordNewSubtitle,
                  style: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.65)),
                ),
                const SizedBox(height: 32),
                Text(t.changePasswordNewLabel, style: AppTextStyles.label()),
                const SizedBox(height: 8),
                PasswordInput(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
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
                      if (value == widget.currentPassword) {
                        return ErrorMessages.passwordMustDiffer;
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
                    if (value != _password) {
                      return ErrorMessages.passwordMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: t.changePasswordSubmit,
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
