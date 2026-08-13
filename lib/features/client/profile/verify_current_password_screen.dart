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

/// Première étape du changement de mot de passe : prouver qu'on connaît
/// l'actuel.
///
/// Cette vérification est faite à part (`POST /auth/verify-password`) pour que
/// l'utilisateur sache tout de suite si son mot de passe actuel est bon, sans
/// avoir à composer le nouveau d'abord. Le mot de passe validé est ensuite
/// transmis à l'écran suivant, que `PUT /auth/change-password` exige.
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

    // Le serveur répond 422 sur un mot de passe faux : `lastError` porte alors
    // le détail. Sans erreur remontée, c'est simplement que `valid` est faux.
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.changePasswordTitle,
                    style: AppTextStyles.displayHero()),
                const SizedBox(height: 10),
                Text(
                  t.changePasswordVerifySubtitle,
                  style: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.65)),
                ),
                const SizedBox(height: 32),
                Text(t.changePasswordCurrentLabel,
                    style: AppTextStyles.label()),
                const SizedBox(height: 8),
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
                const SizedBox(height: 28),
                AppButton(
                  label: t.changePasswordContinue,
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
