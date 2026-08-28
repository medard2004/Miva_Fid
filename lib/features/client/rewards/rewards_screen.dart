import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/reward.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_section_header.dart';
import 'package:miva_fid/features/client/widgets/shared/notification_bell_button.dart';
import 'package:miva_fid/features/client/widgets/shared/reward_detail_sheet.dart';

/// Écran des Récompenses et Privilèges.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final rewards = ref.watch(rewardsProvider);
    final unreadNotifs =
        ref.watch(notificationsProvider).where((n) => !n.isRead).length;

    final availableRewards = rewards.where((r) => r.isRedeemable).toList();
    final usedRewards = rewards
        .where((r) => r.status != RewardStatus.available || r.isExpired)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              title: t.rewardsTitle,
              actions: [NotificationBellButton(unreadCount: unreadNotifs)],
            ),

            // ── Contenu défilant ─────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceCard,
                onRefresh: () => ref.read(rewardsProvider.notifier).loadMine(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (availableRewards.isNotEmpty)
                        ...availableRewards.map((reward) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ActiveRewardCard(
                                reward: reward,
                                onUse: () => showRewardDetailSheet(context, ref, reward),
                              ),
                            ))
                      else
                        EmptyState(
                          compact: true,
                          icon: LucideIcons.gift,
                          title: t.rewardsEmptyActiveTitle,
                          message: t.rewardsEmptyActiveMessage,
                        ),
                      const SizedBox(height: 20),
                      Text(t.commonHistory, style: AppTextStyles.titleMedium()),
                      const SizedBox(height: 10),
                      if (usedRewards.isNotEmpty)
                        AppCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            children: usedRewards
                                .map((reward) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: _HistoryRewardRow(reward: reward),
                                    ))
                                .toList(),
                          ),
                        )
                      else
                        EmptyState(
                          compact: true,
                          icon: LucideIcons.history,
                          title: t.rewardsHistoryEmptyTitle,
                          message: t.rewardsHistoryEmptyMessage,
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de récompense disponible.
class _ActiveRewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onUse;
  const _ActiveRewardCard({required this.reward, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reward.restaurantName.toUpperCase(),
                style: AppTextStyles.eyebrow(color: AppColors.primary),
              ),
              if (reward.expiresAt != null)
                StatusBadge(
                  label: reward.daysRemainingText(t.commonCountdownPrefix),
                  tone: reward.isExpiringSoon
                      ? StatusTone.warning
                      : StatusTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (reward.isBirthday) ...[
                const Text('🎂', style: TextStyle(fontSize: 17)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(reward.title,
                    style: AppTextStyles.titleMedium().copyWith(fontSize: 17)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(label: t.rewardsUseButton, onTap: onUse, height: 46),
        ],
      ),
    );
  }
}

/// Ligne d'historique — utilisée ou annulée.
class _HistoryRewardRow extends StatelessWidget {
  final Reward reward;
  const _HistoryRewardRow({required this.reward});

  @override
  Widget build(BuildContext context) {
    final dateFormatLocale =
        Localizations.localeOf(context).languageCode == 'fr'
            ? 'fr_FR'
            : 'en_US';
    final statusLabel = switch (reward.status) {
      RewardStatus.canceled => 'Annulée',
      _ => reward.isExpired ? 'Expirée' : '',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          reward.status == RewardStatus.used
              ? reward.formattedUsedDate(dateFormatLocale)
              : statusLabel,
          style:
              AppTextStyles.monoSmall(color: AppColors.inkMuted(opacity: 0.8)),
        ),
        Expanded(
          child: Text(
            '${reward.restaurantName}  ·  ${reward.title}',
            style: AppTextStyles.bodyMedium(
                color: AppColors.inkMuted(opacity: 0.8)),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
