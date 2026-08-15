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
import '../../client/providers/settings_provider.dart';
import '../../merchant/providers/merchant_auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await ref.read(merchantAuthProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );

      if (!mounted) return;

      if (!ok) {
        setState(() => _error = 'Email ou mot de passe incorrect.');
        return;
      }

      final restaurant = ref.read(merchantAuthProvider).restaurant;
      if (restaurant?.hasBusinessInfo ?? false) {
        context.go('/merchant');
      } else {
        context.go('/auth/merchant/step1');
      }
    } catch (e) {
      debugPrint("Login error: $e");
      if (mounted) {
        setState(() => _error = 'Email ou mot de passe incorrect.');
      }
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/role-select'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sp.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Sp.lg),
                Text('Connexion', style: AppTextStyles.h1())
                    .animate()
                    .slideY(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOut)
                    .fadeIn(),
                const SizedBox(height: Sp.xs),
                Text(
                  'Bienvenue sur Miva-Fid',
                  style: AppTextStyles.bodyMd()
                      .copyWith(color: AppColors.textSecondary),
                )
                    .animate(delay: 50.ms)
                    .slideY(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOut)
                    .fadeIn(),
                const SizedBox(height: Sp.xl),
                AppInput(
                  label: 'Adresse email',
                  hint: 'votre@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => null,
                ),
                AppInput(
                  label: 'Mot de passe',
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/auth/forgot-password'),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Sp.sm),
                  Container(
                    padding: const EdgeInsets.all(Sp.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.dangerTint,
                      borderRadius: Rd.button,
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.circleAlert,
                            color: AppColors.danger, size: 16),
                        const SizedBox(width: Sp.xs),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTextStyles.caption()
                                .copyWith(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Sp.xl),
                AppButton.primary(
                  'Se connecter',
                  onPressed: _login,
                  loading: _loading,
                  icon: LucideIcons.logIn,
                ),
                const SizedBox(height: Sp.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ?',
                      style: AppTextStyles.bodyMd()
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/role-select'),
                      child: Text(
                        "S'inscrire",
                        style: AppTextStyles.bodyMd().copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
