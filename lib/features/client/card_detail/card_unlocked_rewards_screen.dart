import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/notifications/content_unavailable_view.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/models/reward.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/features/client/widgets/shared/reward_detail_sheet.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Écran dédié aux récompenses débloquées d'une carte de fidélité spécifique.
/// Accessible depuis `CardDetailScreen` via "Voir toutes mes récompenses".
class CardUnlockedRewardsScreen extends ConsumerWidget {
  const CardUnlockedRewardsScreen({
    super.key,
    required this.cardId,
  });

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    final card = ref.watch(walletProvider.select((cards) {
      try {
        return cards.firstWhere((c) => c.id == cardId || c.fallbackId == cardId);
      } catch (_) {
        return null;
      }
    }));

    final rewards = card == null
        ? const <Reward>[]
        : ref.watch(rewardsProvider).where((r) => r.cardId == card.id).toList();

    if (card == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppDetailBar(title: 'Récompenses débloquées'),
        body: ContentUnavailableView(
          message: t.cardDetailNotFound,
          actionLabel: 'Voir mon wallet',
          onAction: () => context.go('/client/wallet'),
        ),
      );
    }

    final dateFormatLocale = Localizations.localeOf(context).languageCode == 'fr'
        ? 'fr_FR'
        : 'en_US';

    final availableCount = rewards.where((r) => r.isRedeemable).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppDetailBar(
        title: 'Récompenses débloquées',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Commerce
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.gift, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.restaurantName,
                          style: AppTextStyles.titleMedium().copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$availableCount disponible${availableCount > 1 ? 's' : ''} sur ${rewards.length} au total',
                          style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Liste des Récompenses
            Expanded(
              child: rewards.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.gift, size: 48, color: AppColors.inkMuted(opacity: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune récompense débloquée pour le moment.',
                              style: AppTextStyles.bodyMedium().copyWith(
                                color: AppColors.inkMuted(opacity: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Continuez à cumuler des tampons ou points pour débloquer vos offres !',
                              style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.6)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(rewardsProvider.notifier).loadMine();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: rewards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final reward = rewards[index];
                          return _UnlockedRewardCard(
                            reward: reward,
                            t: t,
                            dateFormatLocale: dateFormatLocale,
                            onTap: () => showRewardDetailSheet(context, ref, reward),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockedRewardCard extends StatelessWidget {
  const _UnlockedRewardCard({
    required this.reward,
    required this.t,
    required this.dateFormatLocale,
    required this.onTap,
  });

  final Reward reward;
  final AppLocalizations t;
  final String dateFormatLocale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isReady = reward.isRedeemable;
    final statusLabel = isReady
        ? t.rewardStatusReady
        : (reward.isExpired ? t.rewardStatusExpired : t.rewardStatusUsed);
    final statusTone = isReady
        ? StatusTone.success
        : (reward.isExpired ? StatusTone.error : StatusTone.neutral);
    final statusIcon =
        isReady ? LucideIcons.circleCheckBig : (reward.isExpired ? LucideIcons.circleX : null);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      elevated: isReady,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: statusLabel,
                tone: statusTone,
                icon: statusIcon,
              ),
              if (reward.expiresAt != null && isReady)
                Text(
                  'Expire le ${DateFormat('dd/MM/yyyy', dateFormatLocale).format(reward.expiresAt!)}',
                  style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.7)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reward.title,
            style: AppTextStyles.titleMedium().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (reward.unlockedAt != null)
                Text(
                  'Débloquée le ${DateFormat('dd MMMM yyyy', dateFormatLocale).format(reward.unlockedAt!)}',
                  style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.6)),
                )
              else
                const SizedBox.shrink(),
              if (isReady)
                Row(
                  children: [
                    Text(
                      'Afficher QR',
                      style: AppTextStyles.label(color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.qrCode, size: 16, color: AppColors.primary),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
