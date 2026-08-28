import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_translator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

/// Changement de mot de passe marchand (connecté) — mirror du flux client
/// (`verify-password` + `change-password`), en un seul écran plutôt que deux
/// (le backend valide déjà `current_password` de façon atomique dans
/// `change-password`, pas besoin d'une étape de vérification séparée).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = AppLocalizations.of(context)!;

    setState(() => _saving = true);
    final ok = await ref
        .read(merchantAuthProvider.notifier)
        .changePassword(_currentCtrl.text, _newCtrl.text);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.errPasswordChangeSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
      return;
    }

    final error = ref.read(merchantAuthProvider).lastError;
    final message = ErrorTranslator.translate(
      error,
      context: ErrorContext.changePassword,
    ).displayMessage ??
        t.errPasswordCurrentIncorrect;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.changePasswordTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Container(
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: Rd.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.changePasswordNewSubtitle,
                  style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: Sp.lg),
                AppInput(
                  label: t.changePasswordCurrentLabel,
                  controller: _currentCtrl,
                  obscureText: true,
                  accentColor: AppColors.merchant,
                  validator: (v) => (v == null || v.isEmpty) ? t.errFieldRequired : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/auth/forgot-password'),
                    child: Text(
                      t.authForgotPasswordLink,
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: Sp.md),
                AppInput(
                  label: t.changePasswordNewLabel,
                  controller: _newCtrl,
                  obscureText: true,
                  accentColor: AppColors.merchant,
                  validator: (v) {
                    if (v == null || v.isEmpty) return t.errFieldRequired;
                    if (v.length < 8) return t.errPasswordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: Sp.md),
                AppInput(
                  label: t.changePasswordConfirmLabel,
                  controller: _confirmCtrl,
                  obscureText: true,
                  accentColor: AppColors.merchant,
                  validator: (v) =>
                      v != _newCtrl.text ? t.errPasswordMismatch : null,
                ),
                const SizedBox(height: Sp.lg),
                AppButton.merchant(
                  t.changePasswordSubmit,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
