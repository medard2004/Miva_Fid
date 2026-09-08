import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/notifications/content_unavailable_view.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_motion.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/models/reward.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_section_header.dart';
import 'package:miva_fid/features/client/widgets/shared/notification_bell_button.dart';
import 'package:miva_fid/features/client/widgets/shared/reward_detail_sheet.dart';

/// Onglets de filtrage de la page Récompenses.
enum RewardFilterTab { unlocked, locked, history }

/// Écran des Récompenses et Privilèges avec sélecteur d'état :
/// Débloquées (prêtes à l'emploi), À débloquer (en cours de progression) et Historique (utilisées/expirées).
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key, this.openRewardId});

  final String? openRewardId;

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  RewardFilterTab _currentTab = RewardFilterTab.unlocked;
  bool _handledOpenReward = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeOpenReward();
  }

  @override
  void didUpdateWidget(covariant RewardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openRewardId != widget.openRewardId) {
      _handledOpenReward = false;
      _maybeOpenReward();
    }
  }

  void _maybeOpenReward() {
    final rewardId = widget.openRewardId;
    if (rewardId == null || _handledOpenReward) return;
    _handledOpenReward = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reward =
          ref.read(rewardsProvider).where((r) => r.id == rewardId).firstOrNull;
      if (reward == null) {
        showContentUnavailableDialog(
          context,
          message: 'Cette récompense n\'est plus disponible.',
          actionLabel: 'OK',
          onAction: () {},
        );
        return;
      }
      showRewardDetailSheet(context, ref, reward);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final rewards = ref.watch(rewardsProvider);
    final cards = ref.watch(walletProvider);
    final unreadNotifs =
        ref.watch(notificationsProvider).where((n) => !n.isRead).length;

    final availableRewards = rewards.where((r) => r.isRedeemable).toList();
    final usedRewards = rewards
        .where((r) => r.status != RewardStatus.available || r.isExpired)
        .toList();

    // Construction de la liste des récompenses à débloquer depuis les cartes actives
    final lockedTiers = <_UpcomingRewardItem>[];
    for (final card in cards) {
      if (card.tiers.isNotEmpty) {
        for (final tier in card.tiers) {
          if (tier.status != 'reached') {
            final currentVal = card.mechanic == LoyaltyMechanic.stamps
                ? card.stampsCurrent
                : (card.mechanic == LoyaltyMechanic.points ? card.pointsBalance : card.stampsCurrent);
            lockedTiers.add(_UpcomingRewardItem(
              restaurantName: card.restaurantName,
              cardId: card.id,
              liningColor: card.liningColor,
              title: tier.rewardDescription.isNotEmpty
                  ? tier.rewardDescription
                  : (tier.levelName ?? 'Palier ${tier.order}'),
              currentProgress: currentVal,
              goal: tier.goal,
              mechanic: card.mechanic,
            ));
          }
        }
      } else if (card.nextReward != null && card.nextReward!.rewardDescription.isNotEmpty) {
        final currentVal = card.mechanic == LoyaltyMechanic.stamps
            ? card.stampsCurrent
            : (card.mechanic == LoyaltyMechanic.points ? card.pointsBalance : card.stampsCurrent);
        final goalVal = card.nextReward!.goal > 0
            ? card.nextReward!.goal
            : (card.stampsGoal > 0 ? card.stampsGoal : 10);
        lockedTiers.add(_UpcomingRewardItem(
          restaurantName: card.restaurantName,
          cardId: card.id,
          liningColor: card.liningColor,
          title: card.nextReward!.rewardDescription,
          currentProgress: currentVal,
          goal: goalVal,
          mechanic: card.mechanic,
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              title: t.rewardsTitle,
              actions: [NotificationBellButton(unreadCount: unreadNotifs)],
            ),

            // ── Sélecteur d'onglets (Segmented Control) ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    _SegmentTab(
                      label: 'Débloquées',
                      count: availableRewards.length,
                      selected: _currentTab == RewardFilterTab.unlocked,
                      onTap: () => setState(() => _currentTab = RewardFilterTab.unlocked),
                    ),
                    _SegmentTab(
                      label: 'À débloquer',
                      count: lockedTiers.length,
                      selected: _currentTab == RewardFilterTab.locked,
                      onTap: () => setState(() => _currentTab = RewardFilterTab.locked),
                    ),
                    _SegmentTab(
                      label: 'Historique',
                      count: usedRewards.length,
                      selected: _currentTab == RewardFilterTab.history,
                      onTap: () => setState(() => _currentTab = RewardFilterTab.history),
                    ),
                  ],
                ),
              ),
            ),

            // ── Contenu défilant ─────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceCard,
                onRefresh: () async {
                  await Future.wait([
                    ref.read(rewardsProvider.notifier).loadMine(),
                    ref.read(walletProvider.notifier).loadMine(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                  child: AnimatedSwitcher(
                    duration: AppMotion.pageDuration,
                    switchInCurve: AppMotion.pageCurve,
                    switchOutCurve: AppMotion.pageCurve,
                    child: switch (_currentTab) {
                      RewardFilterTab.unlocked => _buildUnlockedTab(availableRewards, t),
                      RewardFilterTab.locked => _buildLockedTab(lockedTiers),
                      RewardFilterTab.history => _buildHistoryTab(usedRewards, t),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedTab(List<Reward> availableRewards, AppLocalizations t) {
    if (availableRewards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyState(
          compact: true,
          icon: LucideIcons.gift,
          title: t.rewardsEmptyActiveTitle,
          message: t.rewardsEmptyActiveMessage,
        ),
      );
    }
    return Column(
      key: const ValueKey('unlocked_list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availableRewards.map((reward) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ActiveRewardCard(
            reward: reward,
            onUse: () => showRewardDetailSheet(context, ref, reward),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLockedTab(List<_UpcomingRewardItem> lockedTiers) {
    if (lockedTiers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyState(
          compact: true,
          icon: LucideIcons.lock,
          title: 'Aucune récompense en attente',
          message: 'Ajoutez des cartes de fidélité ou accumulez des tampons pour débloquer de nouveaux privilèges.',
          action: AppButton(
            label: 'Scanner un QR code',
            fullWidth: false,
            height: 42,
            icon: LucideIcons.scanLine,
            onTap: () => context.push('/client/onboarding/scan'),
          ),
        ),
      );
    }
    return Column(
      key: const ValueKey('locked_list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lockedTiers.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LockedRewardCard(item: item),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab(List<Reward> usedRewards, AppLocalizations t) {
    if (usedRewards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyState(
          compact: true,
          icon: LucideIcons.history,
          title: t.rewardsHistoryEmptyTitle,
          message: t.rewardsHistoryEmptyMessage,
        ),
      );
    }
    return AppCard(
      key: const ValueKey('history_card'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: usedRewards
            .map((reward) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _HistoryRewardRow(reward: reward),
                ))
            .toList(),
      ),
    );
  }
}

/// Bouton d'onglet segmenté moderne avec badge de quantité.
class _SegmentTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Expanded(
      child: AppTapScale(
        onTap: onTap,
        scaleDown: 0.97,
        child: AnimatedContainer(
          duration: AppMotion.pressDuration,
          curve: AppMotion.pressCurve,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF2C3038) : AppColors.surfaceCard)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTextStyles.bodySmall().copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? (isDark ? Colors.white : AppColors.ink)
                          : AppColors.inkMuted(opacity: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.inkMuted(opacity: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.inkMuted(opacity: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de récompense disponible / prête à l'utilisation.
class _ActiveRewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onUse;
  const _ActiveRewardCard({required this.reward, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AppTapScale(
      onTap: onUse,
      scaleDown: 0.99,
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reward.restaurantName.toUpperCase(),
                      style: AppTextStyles.eyebrow(color: AppColors.primary),
                    ),
                  ],
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
            const SizedBox(height: 10),
            Row(
              children: [
                if (reward.isBirthday) ...[
                  Text(reward.isSurprise ? '🎁' : '🎂',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.gift, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    reward.title,
                    style: AppTextStyles.titleMedium().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: t.rewardsUseButton,
              onTap: onUse,
              height: 44,
              icon: LucideIcons.qrCode,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modèle pour une récompense à débloquer.
class _UpcomingRewardItem {
  final String restaurantName;
  final String cardId;
  final Color liningColor;
  final String title;
  final int currentProgress;
  final int goal;
  final LoyaltyMechanic mechanic;

  const _UpcomingRewardItem({
    required this.restaurantName,
    required this.cardId,
    required this.liningColor,
    required this.title,
    required this.currentProgress,
    required this.goal,
    required this.mechanic,
  });
}

/// Carte de récompense verrouillée / en cours de progression.
class _LockedRewardCard extends StatelessWidget {
  final _UpcomingRewardItem item;
  const _LockedRewardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final remaining = (item.goal - item.currentProgress).clamp(0, item.goal);
    final ratio = item.goal > 0 ? (item.currentProgress / item.goal).clamp(0.0, 1.0) : 0.0;
    final unitLabel = item.mechanic == LoyaltyMechanic.stamps ? 'tampons' : 'points';

    return AppTapScale(
      onTap: () => context.push('/client/card/${item.cardId}'),
      scaleDown: 0.99,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.restaurantName.toUpperCase(),
                  style: AppTextStyles.eyebrow(color: AppColors.inkMuted(opacity: 0.7)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.lock, size: 12, color: AppColors.inkMuted(opacity: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        'À débloquer',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted(opacity: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.liningColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.gift, size: 18, color: item.liningColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.titleMedium().copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        remaining > 0
                            ? 'Plus que $remaining $unitLabel pour l\'obtenir'
                            : 'Objectif atteint !',
                        style: AppTextStyles.bodySmall(
                          color: AppColors.inkMuted(opacity: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(item.liningColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.currentProgress} / ${item.goal} $unitLabel',
                  style: AppTextStyles.monoSmall(color: AppColors.inkMuted(opacity: 0.6)),
                ),
                Text(
                  '${(ratio * 100).toInt()}%',
                  style: AppTextStyles.monoSmall(color: AppColors.inkMuted(opacity: 0.6)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'historique — utilisée ou expirée.
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
      _ => reward.isExpired ? 'Expirée' : 'Utilisée',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              reward.status == RewardStatus.used ? LucideIcons.circleCheck : LucideIcons.circleX,
              size: 14,
              color: reward.status == RewardStatus.used
                  ? const Color(0xFF10B981)
                  : AppColors.inkMuted(opacity: 0.45),
            ),
            const SizedBox(width: 8),
            Text(
              reward.status == RewardStatus.used
                  ? reward.formattedUsedDate(dateFormatLocale)
                  : statusLabel,
              style: AppTextStyles.monoSmall(color: AppColors.inkMuted(opacity: 0.7)),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${reward.restaurantName} · ${reward.title}',
            style: AppTextStyles.bodyMedium(color: AppColors.inkMuted(opacity: 0.8)),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
