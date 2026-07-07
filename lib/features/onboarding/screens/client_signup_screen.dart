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

class ClientSignupScreen extends ConsumerStatefulWidget {
  const ClientSignupScreen({super.key});

  @override
  ConsumerState<ClientSignupScreen> createState() => _ClientSignupScreenState();
}

class _ClientSignupScreenState extends ConsumerState<ClientSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (res.user == null) throw Exception('Inscription échouée');

      await Supabase.instance.client.from('users').insert({
        'id': res.user!.id,
        'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'phone': _phoneCtrl.text.trim(),
        'role': 'client',
      });

      if (!mounted) return;
      context.go('/client');
    } catch (e) {
      debugPrint("Signup error: $e");
      if (mounted) context.go('/client');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/role-select'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Créer mon compte', style: AppTextStyles.h1())
                          .animate()
                          .slideY(begin: 0.15, end: 0, duration: 350.ms)
                          .fadeIn(),
                      const SizedBox(height: Sp.xs),
                      Text(
                        'Rejoignez Miva-Fid gratuitement',
                        style: AppTextStyles.bodyMd()
                            .copyWith(color: AppColors.primary),
                      )
                          .animate(delay: 50.ms)
                          .slideY(begin: 0.15, end: 0, duration: 350.ms)
                          .fadeIn(),
                      const SizedBox(height: Sp.xl),
                      Row(
                        children: [
                          Expanded(
                            child: AppInput(
                              label: 'Prénom',
                              hint: 'Kofi',
                              controller: _firstNameCtrl,
                              textInputAction: TextInputAction.next,
                              validator: (v) => null,
                            ),
                          ),
                          const SizedBox(width: Sp.sm),
                          Expanded(
                            child: AppInput(
                              label: 'Nom',
                              hint: 'Mensah',
                              controller: _lastNameCtrl,
                              textInputAction: TextInputAction.next,
                              validator: (v) => null,
                            ),
                          ),
                        ],
                      ),
                      AppInput(
                        label: 'Téléphone',
                        hint: '90 00 00 00',
                        controller: _phoneCtrl,
                        prefixText: '+228 ',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
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
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(Sp.sm),
                          decoration: BoxDecoration(
                            color: AppColors.dangerTint,
                            borderRadius: Rd.button,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Sp.md,
                  0,
                  Sp.md,
                  MediaQuery.of(context).padding.bottom + Sp.md,
                ),
                child: Column(
                  children: [
                    AppButton.primary(
                      'Créer mon compte',
                      onPressed: _register,
                      loading: _loading,
                    ),
                    const SizedBox(height: Sp.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Déjà un compte ?',
                          style: AppTextStyles.caption()
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.go('/auth/login'),
                          child: Text(
                            'Se connecter',
                            style: AppTextStyles.caption()
                                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
