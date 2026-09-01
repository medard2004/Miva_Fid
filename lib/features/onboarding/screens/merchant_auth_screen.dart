import 'package:flutter/gestures.dart';
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
import '../../../core/widgets/password_rules_checklist.dart';
import '../../../core/services/social_auth_service.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/errors/error_translator.dart';
import '../../../core/utils/toast_service.dart';
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
  final bool _loginAsStaff = false;
  bool _loading = false;
  bool _acceptedTerms = false;
  bool _showTermsError = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => context.push('/client/legal/terms');
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => context.push('/client/legal/privacy');

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (!_isLogin && mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onPasswordChanged);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _continueWithSocial(String provider) async {
    if (!_isLogin && !_acceptedTerms) {
      setState(() => _showTermsError = true);
      return;
    }

    setState(() => _loading = true);

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
        ToastService.showError(_translatedError(
          ErrorContext.socialLogin,
          fallback: ErrorMessages.socialFailedGoogle,
        ));
        return;
      }

      final restaurant = ref.read(merchantAuthProvider).restaurant;
      // Repart du compte réel : évite de rejouer les saisies d'un parcours
      // précédent, et préremplit un onboarding repris en cours de route.
      ref.read(onboardingNotifierProvider.notifier).hydrateFrom(restaurant);
      if (restaurant?.hasLoyaltyProgram ?? false) {
        context.go('/merchant/validate');
      } else {
        context.go('/auth/merchant/step1');
      }
    } catch (e) {
      debugPrint("Merchant social auth error: $e");
      if (ErrorTranslator.isUserCancellation(e)) return;
      ToastService.showError(ErrorTranslator.translate(
            e,
            context: ErrorContext.socialLogin,
          ).displayMessage ??
          ErrorMessages.socialFailedGoogle);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Traduit la dernière erreur du provider marchand en message affichable.
  String _translatedError(ErrorContext context, {required String fallback}) {
    final error = ref.read(merchantAuthProvider).lastError;
    return ErrorTranslator.translate(error, context: context).displayMessage ??
        fallback;
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isLogin && !_acceptedTerms) {
      setState(() => _showTermsError = true);
      return;
    }

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      if (_isLogin) {
        // --- CONNEXION ---
        final ok = _loginAsStaff
            ? await ref.read(merchantAuthProvider.notifier).staffLogin(email, password)
            : await ref.read(merchantAuthProvider.notifier).login(email, password);

        if (!mounted) return;

        if (!ok) {
          ToastService.showError(_translatedError(
            ErrorContext.merchantLogin,
            fallback: ErrorMessages.merchantLoginInvalidCredentials,
          ));
          return;
        }

        final restaurant = ref.read(merchantAuthProvider).restaurant;
        if (restaurant?.hasBusinessInfo ?? false) {
          context.go('/merchant/validate');
        } else {
          context.go('/auth/merchant/step1');
        }
      } else {
        // --- INSCRIPTION ---
        final notifier = ref.read(onboardingNotifierProvider.notifier);
        final ok = await notifier.registerUser(email, password);

        if (!mounted) return;

        if (ok) {
          // Compte neuf : on repart d'un état vierge plutôt que des valeurs
          // laissées par un parcours précédent de la même session.
          ref.read(onboardingNotifierProvider.notifier).reset();
          context.go('/auth/merchant/step1');
        } else {
          ToastService.showError(_translatedError(
            ErrorContext.signup,
            fallback: ErrorMessages.signupFailed,
          ));
        }
      }
    } catch (e) {
      debugPrint("Merchant auth error: $e");
      ToastService.showError(ErrorTranslator.translate(
            e,
            context: _isLogin ? ErrorContext.merchantLogin : ErrorContext.signup,
          ).displayMessage ??
          (_isLogin ? ErrorMessages.merchantLoginInvalidCredentials : ErrorMessages.signupFailed));
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
                    color: AppColors.border,
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
                              setState(() => _isLogin = false);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  !_isLogin ? AppColors.surface : Colors.transparent,
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
                              setState(() => _isLogin = true);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  _isLogin ? AppColors.surface : Colors.transparent,
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
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return "Veuillez entrer votre adresse email";
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                      return "Adresse email invalide";
                    }
                    return null;
                  },
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
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    // À la connexion, un compte existant a pu être créé sous
                    // l'ancienne règle (6 caractères) : on ne bloque que la
                    // saisie vide, la complexité n'est exigée qu'à l'inscription.
                    if (_isLogin) return null;
                    if (v.length < 8) {
                      return 'Le mot de passe doit contenir au moins 8 caractères';
                    }
                    if (!v.contains(RegExp(r'[A-Z]'))) {
                      return 'Le mot de passe doit contenir une majuscule';
                    }
                    if (!v.contains(RegExp(r'[0-9]'))) {
                      return 'Le mot de passe doit contenir un chiffre';
                    }
                    return null;
                  },
                )
                    .animate(key: ValueKey('pass_$_isLogin'))
                    .fadeIn(duration: 300.ms),

                // Checklist dynamique des exigences de mot de passe (inscription)
                if (!_isLogin)
                  PasswordRulesChecklist(password: _passwordCtrl.text),

                // "Mot de passe oublié" for login — le flux `/auth/forgot-password`
                // réinitialise le mot de passe du compte Restaurant, pas celui
                // d'un `StaffUser` : un opérateur qui l'emprunterait se
                // retrouverait à réinitialiser un mot de passe qui n'est pas le
                // sien. Un opérateur doit passer par son administrateur.
                if (_isLogin && !_loginAsStaff) ...[
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

                const SizedBox(height: Sp.md),

                // Consentement CGU / confidentialité — inscription uniquement.
                if (!_isLogin) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) => setState(() {
                            _acceptedTerms = value ?? false;
                            if (_acceptedTerms) _showTermsError = false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            _acceptedTerms = !_acceptedTerms;
                            if (_acceptedTerms) _showTermsError = false;
                          }),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'J\'accepte les '),
                                TextSpan(
                                  text: 'CGU',
                                  style: AppTextStyles.caption().copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: _termsTap,
                                ),
                                const TextSpan(text: ' et la '),
                                TextSpan(
                                  text: 'politique de confidentialité',
                                  style: AppTextStyles.caption().copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: _privacyTap,
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showTermsError) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Vous devez accepter les CGU et la politique de confidentialité.',
                      style: AppTextStyles.caption().copyWith(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: Sp.md),
                ],

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
                  leading: Icon(SimpleIcons.apple, size: 18, color: AppColors.textPrimary),
                  onTap: () {
                    if (!_loading) _continueWithSocial('apple');
                  },
                ).animate().fadeIn(duration: 450.ms),

                const SizedBox(height: Sp.xl),

                // 6. Footer Links — inscription : déjà couvert par la case à
                // cocher ci-dessus. Connexion : simple rappel, pas de re-consentement.
                if (_isLogin)
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
                            recognizer: _termsTap,
                          ),
                          TextSpan(text: ' et la '),
                          TextSpan(
                            text: 'politique de confidentialité',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _privacyTap,
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
        color: AppColors.surface,
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
