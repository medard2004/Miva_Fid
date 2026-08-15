import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_toast.dart';
import '../../client/providers/settings_provider.dart';
import '../../merchant/providers/merchant_auth_provider.dart';

/// Étape 3 (finale) de la réinitialisation marchand : nouveau mot de passe.
class MerchantResetPasswordScreen extends ConsumerStatefulWidget {
  const MerchantResetPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  final String email;
  final String resetToken;

  @override
  ConsumerState<MerchantResetPasswordScreen> createState() =>
      _MerchantResetPasswordScreenState();
}

class _MerchantResetPasswordScreenState
    extends ConsumerState<MerchantResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await ref.read(merchantAuthProvider.notifier).resetPassword(
          widget.email,
          widget.resetToken,
          _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      AppToast.success(context, 'Mot de passe réinitialisé.');
      context.go('/auth/merchant/auth');
    } else {
      setState(() => _error = 'La session a expiré. Recommencez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.textPrimary),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/auth/merchant/auth'),
                ),
                const SizedBox(height: Sp.md),

                Text(
                  'Nouveau mot de passe',
                  style: AppTextStyles.h2().copyWith(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(height: Sp.xs),
                Text(
                  'Choisissez un mot de passe pour ${widget.email}.',
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: Sp.md),

                AppInput(
                  label: 'NOUVEAU MOT DE PASSE',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  prefixIcon: LucideIcons.lock,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Le mot de passe doit contenir au moins 6 caractères'
                      : null,
                ),
                AppInput(
                  label: 'CONFIRMER LE MOT DE PASSE',
                  hint: '••••••••',
                  controller: _confirmCtrl,
                  prefixIcon: LucideIcons.lock,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _passwordCtrl.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),

                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.circleAlert, color: AppColors.danger, size: 18),
                        const SizedBox(width: Sp.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTextStyles.caption().copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake(duration: 300.ms),
                  const SizedBox(height: Sp.md),
                ],

                const SizedBox(height: Sp.md),

                AppButton.merchant(
                  'Réinitialiser',
                  icon: LucideIcons.check,
                  loading: _loading,
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
