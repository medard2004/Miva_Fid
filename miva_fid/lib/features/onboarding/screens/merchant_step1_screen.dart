import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/commerce_type_grid.dart';
import '../widgets/onboarding_progress_bar.dart';

class MerchantStep1Screen extends ConsumerStatefulWidget {
  const MerchantStep1Screen({super.key});

  @override
  ConsumerState<MerchantStep1Screen> createState() =>
      _MerchantStep1ScreenState();
}

class _MerchantStep1ScreenState extends ConsumerState<MerchantStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameCtrl = TextEditingController();
  late final _lastNameCtrl = TextEditingController();
  late final _emailCtrl = TextEditingController();
  late final _passwordCtrl = TextEditingController();
  late final _phoneCtrl = TextEditingController();
  late final _commerceNameCtrl = TextEditingController();
  late final _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _commerceNameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setFirstName(_firstNameCtrl.text.trim());
    notifier.setLastName(_lastNameCtrl.text.trim());
    notifier.setEmail(_emailCtrl.text.trim());
    notifier.setPassword(_passwordCtrl.text);
    notifier.setPhone(_phoneCtrl.text.trim());
    notifier.setCommerceName(_commerceNameCtrl.text.trim());
    notifier.setAddress(_addressCtrl.text.trim());

    final ok = await notifier.registerUser();
    if (ok && mounted) context.go('/auth/merchant/step2');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const OnboardingProgressBar(current: 1, total: 5),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Sp.md),
                      Text(
                        'Étape 1 sur 5',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      Text('Créez votre compte', style: AppTextStyles.h1()),
                      const SizedBox(height: Sp.xs),
                      Text(
                        '30 secondes chrono',
                        style: AppTextStyles.bodyMd()
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: Sp.lg),
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
                        label: 'Email professionnel',
                        hint: 'votre@commerce.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) => null,
                      ),
                      AppInput(
                        label: 'Mot de passe',
                        controller: _passwordCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) => null,
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
                        label: 'Nom de votre commerce',
                        hint: 'Restaurant Chez Kofi',
                        controller: _commerceNameCtrl,
                        textInputAction: TextInputAction.next,
                        validator: (v) => null,
                      ),
                      CommerceTypeGrid(
                        selected: ref
                            .watch(onboardingNotifierProvider)
                            .commerceType,
                        onSelected: (t) => ref
                            .read(onboardingNotifierProvider.notifier)
                            .setCommerceType(t),
                      ),
                      AppInput(
                        label: 'Adresse de votre commerce',
                        hint: 'Quartier Bè, Lomé',
                        controller: _addressCtrl,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      if (state.error != null)
                        Container(
                          padding: const EdgeInsets.all(Sp.sm),
                          decoration: BoxDecoration(
                            color: AppColors.dangerTint,
                            borderRadius: Rd.button,
                          ),
                          child: Text(
                            state.error!,
                            style: AppTextStyles.caption()
                                .copyWith(color: AppColors.danger),
                          ),
                        ),
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
                child: AppButton.primary(
                  'Créer mon compte',
                  onPressed: _next,
                  loading: state.isLoading,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
