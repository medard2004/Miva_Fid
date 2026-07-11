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
import '../providers/onboarding_provider.dart';

class MerchantAuthScreen extends ConsumerStatefulWidget {
  const MerchantAuthScreen({super.key});

  @override
  ConsumerState<MerchantAuthScreen> createState() => _MerchantAuthScreenState();
}

class _MerchantAuthScreenState extends ConsumerState<MerchantAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = false; // false = Inscription, true = Connexion
  bool _loading = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        // --- CONNEXION ---
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

        if (!mounted) return;
        if (res.user == null) throw Exception('Connexion échouée');

        // Check if merchant profile already exists
        final merchantData = await Supabase.instance.client
            .from('merchants')
            .select('user_id')
            .eq('user_id', res.user!.id)
            .maybeSingle();

        if (!mounted) return;

        if (merchantData != null) {
          // Profile exists -> dashboard
          context.go('/merchant');
        } else {
          // Profile doesn't exist -> start setup flow
          context.go('/auth/merchant/step1');
        }
      } else {
        // --- INSCRIPTION ---
        final notifier = ref.read(onboardingNotifierProvider.notifier);

        // Sign up & insert user record
        final ok = await notifier.registerUser();

        if (!mounted) return;

        if (ok) {
          context.go('/auth/merchant/step1');
        } else {
          throw Exception("Erreur lors de la création du compte.");
        }
      }
    } catch (e) {
      debugPrint("Merchant auth error: $e");
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Row (Logo + Text side-by-side)
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Miva-Fid',
                            style: AppTextStyles.h3().copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Fidélité digitale pour commerçants',
                            style: AppTextStyles.caption().copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 350.ms),

                const SizedBox(height: Sp.xl),

                // 2. Title & Subtitle
                Text(
                  _isLogin ? 'Bon retour !' : 'Créer votre compte',
                  style: AppTextStyles.h1().copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                )
                    .animate(key: ValueKey('title_$_isLogin'))
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: 4),
                Text(
                  _isLogin
                      ? 'Connectez-vous pour accéder à votre tableau de bord.'
                      : 'Quelques infos et votre programme est prêt.',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                  ),
                )
                    .animate(key: ValueKey('subtitle_$_isLogin'))
                    .fadeIn(duration: 200.ms),

                const SizedBox(height: Sp.xl),

                // 3. Segmented Capsule Control
                Container(
                  height: 46,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 245, 244, 255),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      // Inscription Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isLogin) {
                              setState(() {
                                _isLogin = false;
                                _error = null;
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  !_isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: !_isLogin
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Inscription',
                              style: AppTextStyles.bodyMd().copyWith(
                                fontWeight: !_isLogin
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: !_isLogin
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Connexion Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isLogin) {
                              setState(() {
                                _isLogin = true;
                                _error = null;
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  _isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: _isLogin
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Connexion',
                              style: AppTextStyles.bodyMd().copyWith(
                                fontWeight: _isLogin
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: _isLogin
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: Sp.xl),

                // 4. Form Fields
                // Common Email & Password
                AppInput(
                  label: 'EMAIL',
                  hint: 'vous@exemple.com',
                  controller: _emailCtrl,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Veuillez entrer votre adresse email"
                      : null,
                )
                    .animate(key: ValueKey('email_$_isLogin'))
                    .fadeIn(duration: 300.ms),

                AppInput(
                  label: 'MOT DE PASSE',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Le mot de passe doit contenir au moins 6 caractères'
                      : null,
                )
                    .animate(key: ValueKey('pass_$_isLogin'))
                    .fadeIn(duration: 300.ms),

                // "Mot de passe oublié" for login
                if (_isLogin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/auth/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Mot de passe oublié ?',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 200.ms),
                  const SizedBox(height: Sp.md),
                ],

                // Error Banner
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Sp.md, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 18),
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

                // 5. Submit Button
                AppButton.merchant(
                  _isLogin ? 'Se connecter' : 'Créer mon compte',
                  icon: Icons.arrow_forward_rounded,
                  loading: _loading,
                  onPressed: _handleSubmit,
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: Sp.md),

                // Divider: OU CONTINUER AVEC
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.5), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                      child: Text(
                        'OU CONTINUER AVEC',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.5), thickness: 1)),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: Sp.md),

                // Google button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      // Handle Google Sign In
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red.shade400, width: 1.5),
                            ),
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: Sp.sm),
                          Text(
                            'Continuer avec Google',
                            style: AppTextStyles.labelBold().copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: Sp.xl),

                // 6. Footer Links
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                      children: const [
                        TextSpan(text: 'En continuant, vous acceptez les '),
                        TextSpan(
                          text: 'CGU',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' et la '),
                        TextSpan(
                          text: 'politique de confidentialité',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 450.ms),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
