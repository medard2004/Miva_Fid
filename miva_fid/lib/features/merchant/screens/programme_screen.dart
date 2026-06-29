import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/loyalty_card_preview.dart';
import '../../onboarding/widgets/stamp_stepper.dart';
import '../providers/merchant_provider.dart';

class ProgrammeScreen extends ConsumerStatefulWidget {
  const ProgrammeScreen({super.key});

  @override
  ConsumerState<ProgrammeScreen> createState() => _ProgrammeScreenState();
}

class _ProgrammeScreenState extends ConsumerState<ProgrammeScreen> {
  final _rewardCtrl = TextEditingController();
  int _stamps = 10;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = ref.read(merchantNotifierProvider).value;
      if (m != null) {
        setState(() {
          _stamps = m.stampsRequired;
          _rewardCtrl.text = m.rewardDescription ?? '';
        });
        // Sync onboarding state for the preview card
        ref.read(onboardingNotifierProvider.notifier)
          ..setCommerceName(m.name)
          ..setCommerceType(m.category)
          ..setColorPrimary(m.primaryColor)
          ..setStampsRequired(m.stampsRequired);
      }
    });
  }

  @override
  void dispose() {
    _rewardCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    ref.read(onboardingNotifierProvider.notifier).setStampsRequired(_stamps);
    await ref.read(merchantNotifierProvider.notifier).updateProgramme({
      'stamps_required': _stamps,
      'reward_description': _rewardCtrl.text.trim(),
    });
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Programme mis à jour')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(merchantNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: merchantAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Sp.md),
            child: Column(children: [SkeletonCard(height: 200), SkeletonCard()]),
          ),
          error: (_, __) =>
              Center(child: Text('Erreur', style: AppTextStyles.bodyMd())),
          data: (merchant) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mon Programme', style: AppTextStyles.h1()),
                      const SizedBox(height: Sp.xs),
                      Text('Modifiez votre programme de fidélité',
                          style: AppTextStyles.bodyMd()
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: Sp.lg),
                      const LoyaltyCardPreview(previewStamps: 6),
                      const SizedBox(height: Sp.xl),
                      Text('Nombre de tampons requis',
                          style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.sm),
                      StampStepper(
                        value: _stamps,
                        onChanged: (v) => setState(() => _stamps = v),
                      ),
                      const SizedBox(height: Sp.lg),
                      AppInput(
                        label: 'Récompense',
                        hint: 'Ex : 1 café offert, 10% de réduction',
                        controller: _rewardCtrl,
                        prefixIcon: Icons.card_giftcard_outlined,
                      ),
                      if (merchant != null && !merchant.isPro) ...[
                        const SizedBox(height: Sp.md),
                        Container(
                          padding: const EdgeInsets.all(Sp.md),
                          decoration: BoxDecoration(
                            color: AppColors.warningTint,
                            borderRadius: Rd.card,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline,
                                  color: AppColors.warning, size: 18),
                              const SizedBox(width: Sp.sm),
                              Expanded(
                                child: Text(
                                  'Passez à Pro pour les statistiques avancées et SMS illimités.',
                                  style: AppTextStyles.caption()
                                      .copyWith(color: AppColors.warning),
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
                    MediaQuery.of(context).padding.bottom + Sp.md),
                child: AppButton.primary('Enregistrer',
                    icon: Icons.save_outlined,
                    onPressed: _save,
                    loading: _saving),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
