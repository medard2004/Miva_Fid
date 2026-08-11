import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      debugPrint('Reset password error: $e');
      // Even on error show success to avoid email enumeration
      if (mounted) setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar row ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.sm,
                vertical: Sp.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/auth/merchant/auth');
                      }
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.md,
                  vertical: Sp.sm,
                ),
                child: _sent ? _buildSuccess() : _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form View ──────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Sp.md),

          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.merchantTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.merchant.withValues(alpha: 0.16), width: 1.2),
            ),
            child: const Icon(
              LucideIcons.keyRound,
              color: AppColors.merchant,
              size: 24,
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: Sp.md),

          // Title
          Text(
            'Mot de passe oublié ?',
            style: AppTextStyles.h2().copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),

          const SizedBox(height: Sp.xs),

          Text(
            'Recevez un lien pour réinitialiser votre accès.',
            style: AppTextStyles.bodyMd().copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ).animate(delay: 50.ms).fadeIn(duration: 350.ms),

          const SizedBox(height: Sp.md),

          // Email field
          AppInput(
            label: 'ADRESSE EMAIL',
            hint: 'vous@exemple.com',
            controller: _emailCtrl,
            prefixIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Veuillez entrer votre adresse email';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Adresse email invalide';
              }
              return null;
            },
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms),

          // Error banner
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
                  const Icon(
                    LucideIcons.circleAlert,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().shake(duration: 300.ms),
            const SizedBox(height: Sp.md),
          ],

          const SizedBox(height: Sp.md),

          // Send button
          AppButton.merchant(
            'Envoyer le lien',
            icon: LucideIcons.send,
            loading: _loading,
            onPressed: _sendResetLink,
          ).animate(delay: 150.ms).fadeIn(duration: 350.ms),

          const SizedBox(height: Sp.xl),

          // Info note
          Container(
            padding: const EdgeInsets.all(Sp.md),
            decoration: BoxDecoration(
              color: AppColors.merchantTint.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.merchant.withValues(alpha: 0.16),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  color: AppColors.merchant,
                  size: 18,
                ),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Text(
                    'Vérifiez votre dossier spam si vous ne recevez pas l\'email dans les prochaines minutes.',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.merchantDark,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 350.ms),
        ],
      ),
    );
  }

  // ── Success View ───────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: Sp.xl),

        // Check icon
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.successTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.mailCheck,
            color: AppColors.success,
            size: 40,
          ),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 300.ms),

        const SizedBox(height: Sp.xl),

        Text(
          'Email envoyé !',
          style: AppTextStyles.h1().copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 26,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: Sp.sm),

        Text(
          'Un lien de réinitialisation a été envoyé à :',
          style: AppTextStyles.bodyMd().copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: Sp.xs),

        Text(
          _emailCtrl.text.trim(),
          style: AppTextStyles.bodyMd().copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: Sp.xl),

        // Instructions card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStep(
                icon: LucideIcons.mail,
                title: 'Ouvrez votre boîte mail',
                subtitle: 'Cherchez un email de Miva-Fid',
              ),
              const Divider(height: Sp.lg),
              _buildStep(
                icon: LucideIcons.link,
                title: 'Cliquez sur le lien',
                subtitle: 'Le lien est valide pendant 24h',
              ),
              const Divider(height: Sp.lg),
              _buildStep(
                icon: LucideIcons.lock,
                title: 'Créez un nouveau mot de passe',
                subtitle: 'Au moins 8 caractères recommandés',
              ),
            ],
          ),
        ).animate(delay: 350.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: Sp.xl),

        AppButton.merchant(
          'Retour à la connexion',
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.go('/auth/merchant/auth'),
        ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: Sp.md),

        TextButton(
          onPressed: _sendResetLink,
          child: Text(
            'Renvoyer l\'email',
            style: AppTextStyles.bodyMd().copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate(delay: 450.ms).fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.merchantTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.merchant, size: 20),
        ),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMd().copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
