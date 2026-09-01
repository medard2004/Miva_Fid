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
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Étape finale de l'inscription : choix du mot de passe.
///
/// C'est ici, et seulement ici, que le compte est créé côté serveur
/// (`POST /auth/register`). Les informations d'identité saisies à l'étape
/// précédente attendent dans `signupFlowProvider`.
class CreatePasswordScreen extends ConsumerStatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  ConsumerState<CreatePasswordScreen> createState() =>
      _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends ConsumerState<CreatePasswordScreen>
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

  bool get _hasMinLength => _password.length >= 8;
  bool get _hasUppercase => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit => _password.contains(RegExp(r'[0-9]'));

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context)!;
    final flow = ref.read(signupFlowProvider);

    final success = await runGuarded(
      () => ref.read(authProvider.notifier).register(flow, _password),
      useOverlay: true,
      loadingMessage: t.authLoadingSignup,
    );

    if (!mounted || success == null) return;

    if (success) {
      ref.read(signupFlowProvider.notifier).reset();
      showSuccessToast(ErrorMessages.signupSuccess);
      context.go('/client/wallet');
    } else {
      handleError(
        ref.read(authProvider).lastError,
        context: ErrorContext.signup,
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
                      context.go('/client/signup');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  t.createPasswordTitle,
                  style: AppTextStyles.authTitle(),
                ),
                const SizedBox(height: 8),
                Text(
                  t.createPasswordSubtitle,
                  style: AppTextStyles.bodyMedium(
                      color: AppColors.inkMuted(opacity: 0.6)),
                ),
                const SizedBox(height: 24),
                Text(t.authPasswordLabel, style: AppTextStyles.label()),
                const SizedBox(height: 8),
                PasswordInput(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggle: () => setState(
                      () => _obscurePassword = !_obscurePassword),
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
                const SizedBox(height: 12),
                _RuleRow(
                    label: t.createPasswordRuleMinLength,
                    satisfied: _hasMinLength),
                _RuleRow(
                    label: t.createPasswordRuleUppercase,
                    satisfied: _hasUppercase),
                _RuleRow(
                    label: t.createPasswordRuleDigit,
                    satisfied: _hasDigit),
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
                  label: t.createPasswordButton,
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

/// Ligne de règle du mot de passe, cochée en direct pendant la saisie.
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            size: 16,
            color: satisfied
                ? AppColors.success
                : AppColors.inkMuted(opacity: 0.35),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall(
              color: satisfied
                  ? AppColors.inkMuted(opacity: 0.75)
                  : AppColors.inkMuted(opacity: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
