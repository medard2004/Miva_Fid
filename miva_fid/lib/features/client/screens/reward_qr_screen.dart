import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/rewards_provider.dart';

class RewardQrScreen extends ConsumerWidget {
  const RewardQrScreen({super.key, required this.rewardId});
  final String rewardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardAsync = ref.watch(rewardDetailProvider(rewardId));
    final countdownAsync = ref.watch(countdownProvider(rewardId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/client/rewards'),
        ),
        title: Text('Code de récompense', style: AppTextStyles.h3()),
      ),
      body: rewardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur')),
        data: (reward) {
          if (reward == null) {
            return Center(child: Text('Récompense introuvable', style: AppTextStyles.bodyMd()));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              children: [
                const SizedBox(height: Sp.lg),
                Text('Mon code de récompense',
                    style: AppTextStyles.h2(), textAlign: TextAlign.center),
                const SizedBox(height: Sp.xs),
                Text('Montrez ce code au caissier',
                    style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: Sp.xl),
                Container(
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: Rd.card20,
                    boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: reward.redemptionCode,
                        size: 220,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: AppColors.primary),
                      ),
                      const SizedBox(height: Sp.md),
                      Text(reward.redemptionCode,
                          style: AppTextStyles.monoXl().copyWith(
                              color: AppColors.primary, letterSpacing: 8)),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.xl),
                countdownAsync.when(
                  data: (secs) {
                    final min = secs ~/ 60;
                    final sec = secs % 60;
                    return Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: secs / 300,
                                color: AppColors.primary,
                                backgroundColor: AppColors.border,
                                strokeWidth: 6,
                              ),
                            ),
                            Text(
                              '$min:${sec.toString().padLeft(2, '0')}',
                              style: AppTextStyles.monoXl().copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.sm),
                        Text('Ce code expire dans',
                            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(color: AppColors.primary),
                  error: (_, __) => Column(
                    children: [
                      Text('Code expiré',
                          style: AppTextStyles.bodyMd().copyWith(color: AppColors.danger)),
                      const SizedBox(height: Sp.sm),
                      AppButton.outlined('Générer un nouveau code',
                          color: AppColors.primary,
                          onPressed: () async {
                            await ref.read(rewardsNotifierProvider.notifier).refreshCode(rewardId);
                            ref.invalidate(rewardDetailProvider(rewardId));
                            ref.invalidate(countdownProvider(rewardId));
                          }),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}
