import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/rewards_provider.dart';
import '../widgets/reward_card_widget.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mes Récompenses', style: AppTextStyles.h1()),
                  const SizedBox(height: Sp.xs),
                  Text('Utilisez vos récompenses chez vos commerçants',
                      style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),
            Expanded(
              child: rewardsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(Sp.md),
                  itemCount: 4,
                  itemBuilder: (_, __) => const SkeletonListTile(),
                ),
                error: (_, __) => const EmptyState(message: 'Erreur de chargement'),
                data: (rewards) {
                  final available = rewards.where((r) => r.isAvailable).toList();
                  final used = rewards.where((r) => r.isUsed || r.isExpired).toList();

                  if (rewards.isEmpty) {
                    return const EmptyState(
                      message: 'Aucune récompense',
                      subtitle: 'Cumulez des tampons pour débloquer vos premières récompenses',
                      icon: Icons.card_giftcard_outlined,
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(Sp.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (available.isNotEmpty) ...[
                          Text('Disponibles (${available.length})',
                              style: AppTextStyles.labelBold()),
                          const SizedBox(height: Sp.sm),
                          ...available.map((r) => RewardCardWidget(
                              reward: r,
                              onTap: () => context.go('/client/rewards/${r.id}/redeem'))),
                          const SizedBox(height: Sp.md),
                        ],
                        if (used.isNotEmpty) ...[
                          Text('Historique', style: AppTextStyles.labelBold()
                              .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: Sp.sm),
                          ...used.map((r) => RewardCardWidget(reward: r)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
