import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/password_rules_checklist.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

/// Changement de mot de passe marchand (connecté)
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
  void initState() {
    super.initState();
    _newCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _newCtrl.removeListener(_onPasswordChanged);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error?.toString() ?? t.errPasswordCurrentIncorrect),
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
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.changePasswordTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header security info badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B50EC).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B50EC).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          color: Color(0xFF5B50EC),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sécurité du compte',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.changePasswordNewSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                AppInput(
                  label: t.changePasswordCurrentLabel,
                  controller: _currentCtrl,
                  obscureText: true,
                  prefixIcon: LucideIcons.keyRound,
                  accentColor: const Color(0xFF5B50EC),
                  validator: (v) => (v == null || v.isEmpty) ? t.errFieldRequired : null,
                ),
                const SizedBox(height: 12),

                AppInput(
                  label: t.changePasswordNewLabel,
                  controller: _newCtrl,
                  obscureText: true,
                  prefixIcon: LucideIcons.lockKeyhole,
                  accentColor: const Color(0xFF5B50EC),
                  validator: (v) {
                    if (v == null || v.isEmpty) return t.errFieldRequired;
                    if (v.length < 8) return t.errPasswordTooShort;
                    if (!v.contains(RegExp(r'[A-Z]'))) {
                      return 'Le mot de passe doit contenir une majuscule';
                    }
                    if (!v.contains(RegExp(r'[0-9]'))) {
                      return 'Le mot de passe doit contenir un chiffre';
                    }
                    return null;
                  },
                ),
                PasswordRulesChecklist(password: _newCtrl.text),
                const SizedBox(height: 16),

                AppInput(
                  label: t.changePasswordConfirmLabel,
                  controller: _confirmCtrl,
                  obscureText: true,
                  prefixIcon: LucideIcons.lockKeyhole,
                  accentColor: const Color(0xFF5B50EC),
                  validator: (v) =>
                      v != _newCtrl.text ? t.errPasswordMismatch : null,
                ),
                const SizedBox(height: 28),

                AppButton.merchant(
                  t.changePasswordSubmit,
                  loading: _saving,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
