import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/services/social_auth_service.dart';
import '../providers/onboarding_provider.dart';
import '../../client/providers/settings_provider.dart';
import '../../merchant/providers/merchant_auth_provider.dart';

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

  Future<void> _continueWithSocial(String provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final idToken = provider == 'google'
          ? await SocialAuthService.signInWithGoogle()
          : await SocialAuthService.signInWithApple();

      // `null` = l'utilisateur a fermé la feuille du fournisseur.
      if (idToken == null) return;

      final ok = await ref.read(merchantAuthProvider.notifier).socialLogin(
            provider,
            idToken,
            action: _isLogin ? 'login' : 'signup',
          );

      if (!mounted) return;

      if (!ok) {
        final error = ref.read(merchantAuthProvider).lastError;
        throw Exception(error?.toString() ?? 'Connexion échouée.');
      }

      final restaurant = ref.read(merchantAuthProvider).restaurant;
      if (restaurant?.hasBusinessInfo ?? false) {
        context.go('/merchant');
      } else {
        context.go('/auth/merchant/step1');
      }
    } catch (e) {
      debugPrint("Merchant social auth error: $e");
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      if (_isLogin) {
        // --- CONNEXION ---
        final ok =
            await ref.read(merchantAuthProvider.notifier).login(email, password);

        if (!mounted) return;

        if (!ok) {
          final error = ref.read(merchantAuthProvider).lastError;
          throw Exception(error?.toString() ?? 'Connexion échouée.');
        }

        final restaurant = ref.read(merchantAuthProvider).restaurant;
        if (restaurant?.hasBusinessInfo ?? false) {
          context.go('/merchant');
        } else {
          context.go('/auth/merchant/step1');
        }
      } else {
        // --- INSCRIPTION ---
        final notifier = ref.read(onboardingNotifierProvider.notifier);
        final ok = await notifier.registerUser(email, password);

        if (!mounted) return;

        if (ok) {
          context.go('/auth/merchant/step1');
        } else {
          final error = ref.read(merchantAuthProvider).lastError;
          throw Exception(error?.toString() ?? "Erreur lors de la création du compte.");
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
    // Ces ecrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le systeme de dependances de Flutter : observer
    // la luminosite effective est leur seul declencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Back Button
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/role-select');
                    }
                  },
                ),

                const SizedBox(height: Sp.md),

                // 2. Title (Reduced size, no subtitle description)
                Text(
                  _isLogin ? 'Bon retour !' : 'Créer votre compte',
                  style: AppTextStyles.h2().copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                )
                    .animate(key: ValueKey('title_$_isLogin'))
                    .fadeIn(duration: 200.ms),

                const SizedBox(height: Sp.md),

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
                  prefixIcon: LucideIcons.mail,
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
                  prefixIcon: LucideIcons.lock,
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
                        const Icon(LucideIcons.circleAlert,
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
                  icon: LucideIcons.arrowRight,
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

                // Google & Apple buttons
                _SocialAuthButton(
                  label: 'Continuer avec Google',
                  leading: SvgPicture.asset('assets/icons/google_logo.svg', width: 18, height: 18),
                  onTap: () {
                    if (!_loading) _continueWithSocial('google');
                  },
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: Sp.sm),
                _SocialAuthButton(
                  label: 'Continuer avec Apple',
                  leading: const Icon(SimpleIcons.apple, size: 18, color: Colors.black),
                  onTap: () {
                    if (!_loading) _continueWithSocial('apple');
                  },
                ).animate().fadeIn(duration: 450.ms),

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
                      children: [
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

/// Bouton de connexion sociale (Google/Apple) — même style que le module
/// client (fond blanc, bordure fine, ombre légère), icône fournie par
/// l'appelant.
class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: Sp.sm),
              Text(
                label,
                style: AppTextStyles.labelBold().copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
