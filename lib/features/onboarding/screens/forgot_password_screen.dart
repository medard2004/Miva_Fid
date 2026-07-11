import 'package:flutter/material.dart';
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
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.pop(),
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
          const SizedBox(height: Sp.lg),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: Sp.xl),

          // Title
          Text(
            'Mot de passe oublié ?',
            style: AppTextStyles.h1().copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),

          const SizedBox(height: Sp.sm),

          // Subtitle
          Text(
            'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            style: AppTextStyles.bodyMd().copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate(delay: 50.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),

          const SizedBox(height: Sp.xl),

          // Email field
          AppInput(
            label: 'ADRESSE EMAIL',
            hint: 'vous@exemple.com',
            controller: _emailCtrl,
            prefixIcon: Icons.mail_outline_rounded,
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
                    Icons.error_outline_rounded,
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
          AppButton.primary(
            'Envoyer le lien',
            icon: Icons.send_rounded,
            loading: _loading,
            onPressed: _sendResetLink,
          ).animate(delay: 150.ms).fadeIn(duration: 350.ms),

          const SizedBox(height: Sp.xl),

          // Info note
          Container(
            padding: const EdgeInsets.all(Sp.md),
            decoration: BoxDecoration(
              color: AppColors.primaryTint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Text(
                    'Vérifiez votre dossier spam si vous ne recevez pas l\'email dans les prochaines minutes.',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.primary,
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
            Icons.mark_email_read_rounded,
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
            color: Colors.white,
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
                icon: Icons.mail_outlined,
                title: 'Ouvrez votre boîte mail',
                subtitle: 'Cherchez un email de Miva-Fid',
              ),
              const Divider(height: Sp.lg),
              _buildStep(
                icon: Icons.link_rounded,
                title: 'Cliquez sur le lien',
                subtitle: 'Le lien est valide pendant 24h',
              ),
              const Divider(height: Sp.lg),
              _buildStep(
                icon: Icons.lock_outline_rounded,
                title: 'Créez un nouveau mot de passe',
                subtitle: 'Au moins 8 caractères recommandés',
              ),
            ],
          ),
        ).animate(delay: 350.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: Sp.xl),

        AppButton.primary(
          'Retour à la connexion',
          icon: Icons.arrow_back_rounded,
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
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
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
