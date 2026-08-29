import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/notifications/content_unavailable_view.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/core/theme/app_shadows.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:miva_fid/features/client/models/reward.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/features/client/widgets/shared/reward_detail_sheet.dart';
import '../wallet/widgets/card_face_content.dart';
import 'card_export_service.dart';
import '../../../core/widgets/tier_level_icon.dart';

class CardDetailScreen extends ConsumerWidget {
  final String cardId;
  CardDetailScreen({super.key, required this.cardId});

  // Stable pour la durée de vie de cet écran : sert à capturer le visuel
  // exact de la carte (QR + plaque) lors de l'export/partage.
  final GlobalKey _exportBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final card = ref.watch(walletProvider.select((cards) {
      try {
        return cards
            .firstWhere((c) => c.id == cardId || c.fallbackId == cardId);
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
        appBar: AppDetailBar(title: t.cardDetailTitle),
        body: ContentUnavailableView(
          message: t.cardDetailNotFound,
          actionLabel: 'Voir mon wallet',
          onAction: () => context.go('/client/wallet'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: t.cardDetailTitle,
        trailing: IconButton(
          onPressed: () =>
              _showExportModal(context, card, _exportBoundaryKey, t),
          icon: const Icon(LucideIcons.share2,
              color: AppColors.primary, size: 20),
          tooltip: t.cardDetailExportTooltip,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),

                    // Visuel capturé pour l'export/partage : QR + plaque restaurant.
                    RepaintBoundary(
                      key: _exportBoundaryKey,
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: Column(
                          children: [
                            _TopQrPlateCard(card: card, t: t),
                            const SizedBox(height: 8),
                            _MiddleCardWidget(card: card),
                          ],
                        ),
                      ),
                    ),

                    if (card.tiers.length > 1) ...[
                      const SizedBox(height: 20),
                      _CurrentLevelCard(
                        card: card,
                        onSeeAll: () => _showAllLevelsSheet(context, card.tiers),
                      ),
                    ],

                    if (card.mechanic != LoyaltyMechanic.cashback) ...[
                      const SizedBox(height: 20),

                      Text(t.rewardsTitle,
                          style: AppTextStyles.displayMedium()),

                      const SizedBox(height: 10),

                      Builder(builder: (context) {
                        // Multi-palier : la liste inclut aussi un aperçu
                        // verrouillé pour chaque palier pas encore atteint
                        // (y compris ceux de niveau supérieur), pas
                        // seulement les récompenses déjà débloquées.
                        final lockedTiers = card.tiers
                            .where((tier) => tier.status != 'reached')
                            .toList();
                        final showLockedTiers = card.tiers.isNotEmpty;
                        final total = rewards.length +
                            (showLockedTiers
                                ? lockedTiers.length
                                : (rewards.isEmpty ? 1 : 0));

                        if (total == 0) return const SizedBox.shrink();

                        return SizedBox(
                          height: 132,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: total,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              if (i < rewards.length) {
                                return _DetailedRewardCard(
                                  reward: rewards[i],
                                  t: t,
                                  onTap: () => showRewardDetailSheet(
                                      context, ref, rewards[i]),
                                );
                              }
                              if (showLockedTiers) {
                                return _LockedTierCard(
                                  t: t,
                                  tier: lockedTiers[i - rewards.length],
                                  isLevelTier: true,
                                );
                              }
                              return _LockedTierCard(
                                t: t,
                                tier: card.nextReward,
                                fallbackGoal: card.stampsGoal,
                                isLevelTier: false,
                              );
                            },
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 16),

                    _HistoryAccordionBar(card: card, t: t),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal d'exportation et de partage de la carte.
void _showExportModal(BuildContext context, LoyaltyCard card,
    GlobalKey exportKey, AppLocalizations t) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionEyebrow(t.cardDetailExportSheetTitle),
                    const SizedBox(height: 4),
                    Text(card.restaurantName,
                        style: AppTextStyles.displayMedium()
                            .copyWith(fontSize: 20)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x, color: AppColors.ink, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ExportOptionTile(
              icon: LucideIcons.bookmarkPlus,
              title: t.cardDetailSaveTitle,
              subtitle: t.cardDetailSaveSubtitle,
              onTap: () {
                Navigator.pop(context);
                CardExportService.exportAndShareCard(
                    context, card, 'save', exportKey);
              },
            ),
            const SizedBox(height: 10),
            _ExportOptionTile(
              icon: LucideIcons.download,
              title: t.cardDetailDownloadTitle,
              subtitle: t.cardDetailDownloadSubtitle,
              onTap: () {
                Navigator.pop(context);
                CardExportService.exportAndShareCard(
                    context, card, 'download', exportKey);
              },
            ),
            const SizedBox(height: 10),
            _ExportOptionTile(
              icon: LucideIcons.share2,
              title: t.cardDetailShareTitle,
              subtitle: t.cardDetailShareSubtitle,
              isHighlight: true,
              onTap: () {
                Navigator.pop(context);
                CardExportService.exportAndShareCard(
                    context, card, 'share', exportKey);
              },
            ),
          ],
        ),
      );
    },
  );
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isHighlight;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: isHighlight ? AppColors.primary : AppColors.surfaceCard,
      bordered: !isHighlight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            color: isHighlight ? Colors.white : AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label(
                    color: isHighlight ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(
                    color: isHighlight
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.inkMuted(opacity: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: isHighlight
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.inkMuted(opacity: 0.3),
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// Bloc supérieur — QR code scannable et identifiant de carte.
class _TopQrPlateCard extends StatelessWidget {
  final LoyaltyCard card;
  final AppLocalizations t;
  const _TopQrPlateCard({required this.card, required this.t});

  @override
  Widget build(BuildContext context) {
    // Plaque : padding 16*2 (container) + 12*2 (cadre QR) = 56 de marge fixe
    // avant le QR — sur un écran étroit, un QR figé à 170 déborderait sinon.
    final qrSize = (MediaQuery.sizeOf(context).width - 56).clamp(0.0, 170.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.resting,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showFullScreenQrDialog(context, card, t),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: _CardQr(card: card, size: qrSize),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showFullScreenQrDialog(context, card, t),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.maximize2,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(t.cardDetailFullScreen,
                    style: AppTextStyles.label(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  card.fallbackId.replaceAll('-', ' - '),
                  style: AppTextStyles.monoMedium(color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: card.fallbackId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.cardDetailIdCopied)),
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    LucideIcons.copy,
                    size: 15,
                    color: AppColors.inkMuted(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Affiche le QR Code en plein écran dans un modal.
void _showFullScreenQrDialog(
    BuildContext context, LoyaltyCard card, AppLocalizations t) {
  // Dialog : insetPadding 24*2 + padding contenu 24*2 + padding cadre QR
  // 20*2 = 136 de marge fixe avant le QR — sur un écran étroit (~320dp), un
  // QR figé à 230 déborderait sinon.
  final qrSize =
      (MediaQuery.sizeOf(context).width - 136).clamp(0.0, 230.0);
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      card.restaurantName,
                      style:
                          AppTextStyles.displayMedium().copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: AppColors.ink, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: _CardQr(card: card, size: qrSize),
              ),
              const SizedBox(height: 20),
              Text(
                card.fallbackId.replaceAll('-', ' - '),
                style: AppTextStyles.monoMedium(color: AppColors.ink)
                    .copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                t.cardDetailQrInstructions,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall(color: AppColors.inkMuted()),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Carte du restaurant au format compact — Hero partagé avec la pile du wallet.
class _MiddleCardWidget extends StatelessWidget {
  final LoyaltyCard card;
  const _MiddleCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    // Texte toujours blanc — même convention que l'aperçu marchand, qui
    // n'adapte pas la couleur du texte à la luminosité du dégradé.
    const textColor = Colors.white;
    // Responsive height: match ~0.42 aspect ratio (148/full-width) like
    // the merchant preview, with a sensible min/max.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardHeight = (screenWidth * 0.42).clamp(130.0, 180.0);

    return Hero(
      tag: 'card_${card.id}',
      child: Material(
        type: MaterialType.transparency,
        child: GradientCardSurface(
          color: card.liningColor,
          secondaryColor: card.secondaryColor,
          gradientType: card.gradientType,
          decorationPattern: card.decorationPattern,
          width: double.infinity,
          height: cardHeight,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child:
              CardFaceContent(card: card, textColor: textColor, compact: true),
        ),
      ),
    );
  }
}

/// Roadmap verticale des paliers — palier atteint, en cours, et à venir,
/// avec le niveau et la récompense de chacun. Affichée uniquement quand le
/// programme a 2+ paliers (un seul palier = pas de système de niveau, voir
/// `LoyaltyCard.levelName`).
class _TierRoadmap extends StatelessWidget {
  final List<CardTier> tiers;
  const _TierRoadmap({required this.tiers});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < tiers.length; i++) ...[
            _TierRoadmapRow(tier: tiers[i]),
            if (i < tiers.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 18),
                child: Container(width: 2, height: 16, color: AppColors.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _TierRoadmapRow extends StatelessWidget {
  final CardTier tier;
  const _TierRoadmapRow({required this.tier});

  @override
  Widget build(BuildContext context) {
    final isReached = tier.status == 'reached';
    final isCurrent = tier.status == 'current';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReached
                ? AppColors.successTint
                : (isCurrent ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceMuted),
            border: isCurrent ? Border.all(color: AppColors.primary, width: 1.5) : null,
          ),
          child: TierLevelIcon(position: tier.position, iconKey: tier.iconKey, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.levelName ?? 'Palier',
                  style: AppTextStyles.titleMedium().copyWith(
                    fontSize: 14,
                    color: isReached || isCurrent ? AppColors.ink : AppColors.inkMuted(opacity: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Objectif : ${formatGroupedNumber(tier.goal)}',
                  style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.6)),
                ),
                const SizedBox(height: 2),
                Text(
                  tier.rewardDescription.isNotEmpty
                      ? tier.rewardDescription
                      : '🔒 Récompense surprise',
                  style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.7)),
                ),
              ],
            ),
          ),
        ),
        if (isReached)
          const Icon(LucideIcons.circleCheckBig, size: 18, color: AppColors.success),
      ],
    );
  }
}

/// Carte de récompense individuelle.
class _DetailedRewardCard extends StatelessWidget {
  final Reward reward;
  final AppLocalizations t;
  final VoidCallback onTap;
  const _DetailedRewardCard({
    required this.reward,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = reward.isRedeemable;
    final statusLabel = isReady 
        ? t.rewardStatusReady 
        : (reward.isExpired ? t.rewardStatusExpired : t.rewardStatusUsed);
    final statusTone = isReady 
        ? StatusTone.success 
        : (reward.isExpired ? StatusTone.error : StatusTone.neutral);
    final statusIcon = isReady ? LucideIcons.circleCheckBig : (reward.isExpired ? LucideIcons.circleX : null);

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 250,
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          elevated: isReady,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(
                    label: statusLabel,
                    tone: statusTone,
                    icon: statusIcon,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reward.title,
                style: AppTextStyles.titleMedium().copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                reward.restaurantName,
                style: AppTextStyles.bodySmall(
                    color: AppColors.inkMuted(opacity: 0.7)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aperçu d'un palier pas encore atteint — objectif, récompense (masquée
/// côté serveur si le marchand a désactivé `reveal_reward` pour ce palier)
/// et statut verrouillé. Remplace l'ancien texte d'incitation générique.
class _LockedTierCard extends StatelessWidget {
  final AppLocalizations t;
  final CardTier? tier;
  final int? fallbackGoal;

  /// `true` quand [tier] est un vrai palier de la roadmap de niveau (icône
  /// pilotée par sa position/icon_key) ; `false` pour l'aperçu générique de
  /// prochaine récompense d'un programme mono-palier (pas de niveau, voir
  /// `LoyaltyTierService` — icône générique de cadeau).
  final bool isLevelTier;

  const _LockedTierCard({
    required this.t,
    this.tier,
    this.fallbackGoal,
    required this.isLevelTier,
  });

  @override
  Widget build(BuildContext context) {
    final goal = tier?.goal ?? fallbackGoal;
    final description = tier?.rewardDescription ?? '';
    final title = description.isNotEmpty ? description : t.cardDetailDefaultOfferTitle;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 250,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(
                label: t.rewardStatusLocked,
                tone: StatusTone.neutral,
                icon: LucideIcons.lock,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tier != null) ...[
                    isLevelTier
                        ? TierLevelIcon(position: tier!.position, iconKey: tier!.iconKey, size: 15)
                        : Icon(Icons.card_giftcard, size: 15, color: AppColors.inkMuted(opacity: 0.6)),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleMedium().copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (goal != null) ...[
                const SizedBox(height: 3),
                Text(
                  'Objectif : ${formatGroupedNumber(goal)}',
                  style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.7)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte compacte du niveau ACTUEL du cycle en cours — pas la roadmap
/// complète (voir `_showAllLevelsSheet`). Le niveau maximum historique
/// (`LoyaltyCard.max_level_*` côté serveur) reste consultable via l'accordéon
/// d'historique, pas ici : cette carte ne parle que du cycle en cours.
class _CurrentLevelCard extends StatelessWidget {
  final LoyaltyCard card;
  final VoidCallback onSeeAll;
  const _CurrentLevelCard({required this.card, required this.onSeeAll});

  CardTier? get _displayTier {
    if (card.tiers.isEmpty) return null;
    final current = card.tiers.where((tr) => tr.status == 'current');
    if (current.isNotEmpty) return current.first;
    final reached = card.tiers.where((tr) => tr.status == 'reached');
    if (reached.isNotEmpty) return reached.last;
    return card.tiers.first;
  }

  @override
  Widget build(BuildContext context) {
    final tier = _displayTier;

    return AppCard(
      onTap: onSeeAll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: TierLevelIcon(position: tier?.position, iconKey: tier?.iconKey, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.levelName ?? tier?.levelName ?? 'Palier',
                  style: AppTextStyles.titleMedium().copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  card.isMaxLevel
                      ? 'Niveau maximum atteint'
                      : 'Objectif : ${formatGroupedNumber(tier?.goal ?? card.stampsGoal)}',
                  style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.6)),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: AppColors.inkMuted(opacity: 0.5), size: 20),
        ],
      ),
    );
  }
}

/// Popup listant tous les paliers (roadmap complète) — ouvert depuis
/// [_CurrentLevelCard], réutilise `_TierRoadmap` telle quelle.
void _showAllLevelsSheet(BuildContext context, List<CardTier> tiers) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Tous les niveaux', style: AppTextStyles.displayMedium()),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: _TierRoadmap(tiers: tiers),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Accordéon de l'historique — données réelles (`GET /loyalty-cards/{id}/history`),
/// plus l'entrée d'inscription synthétique (pas de ligne serveur pour ça).
class _HistoryAccordionBar extends ConsumerStatefulWidget {
  final LoyaltyCard card;
  final AppLocalizations t;
  const _HistoryAccordionBar({required this.card, required this.t});

  @override
  ConsumerState<_HistoryAccordionBar> createState() => _HistoryAccordionBarState();
}

class _HistoryAccordionBarState extends ConsumerState<_HistoryAccordionBar> {
  bool _expanded = false;

  _HistoryEntry _entryFor(CardHistoryEntry row, AppLocalizations t) {
    final detail = switch (row.type) {
      'cashback_earn' => t.historyCashbackEntry(row.value.round()),
      'cashback_redeem' => t.historyCashbackRedeemEntry(row.value.round()),
      _ => widget.card.mechanic == LoyaltyMechanic.stamps
          ? t.historyStampEntry
          : t.historyPointsEntry(row.value.round()),
    };
    return _HistoryEntry(date: row.date, detail: detail);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final card = widget.card;
    final asyncHistory = ref.watch(cardHistoryProvider(card.id));
    final dateFormatLocale =
        Localizations.localeOf(context).languageCode == 'fr'
            ? 'fr_FR'
            : 'en_US';

    final signup = _HistoryEntry(
      date: card.createdAt ?? DateTime.now(),
      detail: card.welcomeOffer.isNotEmpty ? card.welcomeOffer : t.historySignupEntry,
    );

    final history = asyncHistory.maybeWhen(
      data: (rows) => [
        ...rows.map((r) => _entryFor(r, t)),
        signup,
      ],
      orElse: () => <_HistoryEntry>[],
    );

    return Column(
      children: [
        AppCard(
          onTap: () => setState(() => _expanded = !_expanded),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(t.commonHistory, style: AppTextStyles.titleMedium()),
              const Spacer(),
              if (asyncHistory.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  t.cardDetailVisitsCount(history.length),
                  style: AppTextStyles.eyebrow(color: AppColors.primary),
                ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(LucideIcons.chevronDown,
                    color: AppColors.ink, size: 20),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: history.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              t.cardDetailHistoryEmpty,
                              style: AppTextStyles.bodySmall(
                                  color: AppColors.inkMuted(opacity: 0.7)),
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < history.length; i++) ...[
                                if (i > 0)
                                  Divider(height: 20, color: AppColors.border),
                                _HistoryRow(
                                    entry: history[i],
                                    dateFormatLocale: dateFormatLocale),
                              ],
                            ],
                          ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _HistoryEntry {
  final DateTime date;
  final String detail;
  const _HistoryEntry({required this.date, required this.detail});
}

class _HistoryRow extends StatelessWidget {
  final _HistoryEntry entry;
  final String dateFormatLocale;
  const _HistoryRow({required this.entry, required this.dateFormatLocale});

  @override
  Widget build(BuildContext context) {
    final formatted =
        DateFormat('dd MMMM yyyy', dateFormatLocale).format(entry.date);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(formatted,
              style: AppTextStyles.bodySmall(
                  color: AppColors.inkMuted(opacity: 0.8))),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            entry.detail,
            textAlign: TextAlign.end,
            style: AppTextStyles.monoSmall(),
          ),
        ),
      ],
    );
  }
}

/// QR code scannable de la carte — encode le `card_code`, l'identifiant que
/// `GET /merchant/clients/lookup` accepte côté marchand pour retrouver la
/// carte et accorder un tampon. Remplace l'ancien motif décoratif, qui
/// ressemblait à un QR sans en être un et n'était donc pas scannable.
class _CardQr extends StatelessWidget {
  final LoyaltyCard card;
  final double size;

  const _CardQr({required this.card, required this.size});

  @override
  Widget build(BuildContext context) {
    if (card.fallbackId.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return QrImageView(
      data: card.fallbackId,
      size: size,
      backgroundColor: Colors.white,
      // La plaque reste blanche dans les deux thèmes (lisibilité au scan) :
      // `inkSolid`, pas `ink` qui passerait en quasi-blanc en mode sombre.
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: AppColors.inkSolid,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: AppColors.inkSolid,
      ),
    );
  }
}
