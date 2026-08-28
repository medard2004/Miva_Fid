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
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/errors/error_translator.dart';
import '../../../core/utils/toast_service.dart';
import '../../client/providers/settings_provider.dart';
import '../../merchant/providers/merchant_auth_provider.dart';

/// Étape 2 de la réinitialisation marchand : saisie du code OTP reçu.
class MerchantVerifyOtpScreen extends ConsumerStatefulWidget {
  const MerchantVerifyOtpScreen({super.key, required this.identifier});

  /// Email ou numéro de téléphone renseigné à l'étape précédente.
  final String identifier;

  @override
  ConsumerState<MerchantVerifyOtpScreen> createState() =>
      _MerchantVerifyOtpScreenState();
}

class _MerchantVerifyOtpScreenState
    extends ConsumerState<MerchantVerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final resetToken = await ref
        .read(merchantAuthProvider.notifier)
        .verifyResetOtp(widget.identifier, _otpCtrl.text.trim());

    if (!mounted) return;
    setState(() => _loading = false);

    if (resetToken != null) {
      context.push(
        '/auth/merchant/reset-password',
        extra: {'identifier': widget.identifier, 'reset_token': resetToken},
      );
    } else {
      final error = ref.read(merchantAuthProvider).lastError;
      ToastService.showError(ErrorTranslator.translate(
            error,
            context: ErrorContext.verifyOtp,
          ).displayMessage ??
          ErrorMessages.otpInvalid);
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

                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.merchantTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.merchant.withValues(alpha: 0.16), width: 1.2),
                  ),
                  child: const Icon(LucideIcons.shieldCheck, color: AppColors.merchant, size: 24),
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: Sp.md),

                Text(
                  'Entrez le code',
                  style: AppTextStyles.h2().copyWith(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(height: Sp.xs),
                Text(
                  'Un code à 6 chiffres a été envoyé à ${widget.identifier}.',
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: Sp.md),

                AppInput(
                  label: 'CODE',
                  hint: '••••••',
                  controller: _otpCtrl,
                  prefixIcon: LucideIcons.keyRound,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.trim().length != 6)
                      ? 'Le code doit contenir 6 chiffres'
                      : null,
                ),

                const SizedBox(height: Sp.md),

                AppButton.merchant(
                  'Vérifier',
                  icon: LucideIcons.arrowRight,
                  loading: _loading,
                  onPressed: _verify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
