import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/reward.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:flutter/services.dart';
import 'package:miva_fid/features/client/widgets/shared/app_section_header.dart';
import 'package:miva_fid/features/client/widgets/shared/notification_bell_button.dart';
import 'package:miva_fid/core/constants/reward_qr.dart';

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
                                onUse: () => _showRewardQr(context, ref, reward),
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

/// Affiche le QR unique de la récompense — le marchand le scanne et valide
/// sur place (aucune action locale ne marque la récompense comme utilisée :
/// seule la confirmation marchand le fait). Recharge la liste à la fermeture
/// au cas où la validation aurait déjà eu lieu pendant que le QR était affiché.
Future<void> _showRewardQr(BuildContext context, WidgetRef ref, Reward reward) async {
  final t = AppLocalizations.of(context)!;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SingleChildScrollView(
      child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(reward.title,
              style: AppTextStyles.titleMedium(), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(reward.restaurantName,
              style: AppTextStyles.bodyMedium(
                  color: AppColors.inkMuted(opacity: 0.7)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: '$rewardQrPrefix${reward.redeemToken}',
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.inkSolid,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.inkSolid,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        reward.redeemToken.replaceAll('-', ' - '),
                        style: AppTextStyles.monoMedium(color: AppColors.inkSolid)
                            .copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: reward.redeemToken));
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(t.cardDetailIdCopied)),
                          );
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.copy,
                          size: 16,
                          color: AppColors.inkSolid.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.rewardsShowQrInstruction,
            style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.65)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: t.commonClose,
            onTap: () => Navigator.of(sheetContext).pop(),
            height: 46,
          ),
        ],
      ),
      ),
    ),
  );
  await ref.read(rewardsProvider.notifier).loadMine();
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
              Expanded(
                child: Text(
                  reward.restaurantName.toUpperCase(),
                  style: AppTextStyles.eyebrow(color: AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (reward.expiresAt != null) ...[
                const SizedBox(width: 8),
                StatusBadge(
                  label: reward.daysRemainingText(t.commonCountdownPrefix),
                  tone: reward.isExpiringSoon
                      ? StatusTone.warning
                      : StatusTone.neutral,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(reward.title,
              style: AppTextStyles.titleMedium().copyWith(fontSize: 17)),
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
        Flexible(
          child: Text(
            reward.status == RewardStatus.used
                ? reward.formattedUsedDate(dateFormatLocale)
                : statusLabel,
            style: AppTextStyles.monoSmall(
                color: AppColors.inkMuted(opacity: 0.8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${reward.restaurantName}  ·  ${reward.title}',
            style: AppTextStyles.bodyMedium(
                color: AppColors.inkMuted(opacity: 0.8)),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
