import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:miva_fid/core/constants/referral_qr.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/core/theme/app_shadows.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/models/referral.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/providers/referral_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_section_header.dart';
import 'package:miva_fid/features/client/widgets/shared/notification_bell_button.dart';

/// Écran de Parrainage — QR/identifiant de parrainage propre à chaque carte
/// (donc à chaque établissement, voir `LoyaltyCard.referralQrToken`). La
/// récompense n'est jamais accordée ici : elle arrive quand le filleul
/// effectue sa première opération de fidélité (voir backend
/// `ReferralService::validateFirstOperation`), reflétée par le passage de
/// pending à validated dans la liste ci-dessous.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  String? _selectedCardId;

  void _share(LoyaltyCard card, AppLocalizations t) {
    Share.share(t.referralShareMessage(card.restaurantName, card.referralCode ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final allCards = ref.watch(walletProvider);
    final cards = allCards.where((c) => c.referralQrToken != null).toList();
    final referrals = ref.watch(referralProvider);
    final unreadNotifs =
        ref.watch(notificationsProvider).where((n) => !n.isRead).length;

    if (cards.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              AppSectionHeader(
                title: t.referralTitle,
                actions: [NotificationBellButton(unreadCount: unreadNotifs)],
              ),
              Expanded(
                child: Center(
                  child: EmptyState(
                    icon: LucideIcons.users,
                    title: t.referralEmptyTitle,
                    message: t.referralEmptyMessage,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final selectedCard = cards.firstWhere(
      (c) => c.id == _selectedCardId,
      orElse: () => cards.first,
    );
    final cardReferrals =
        referrals.where((r) => r.restaurantName == selectedCard.restaurantName).toList();
    final pending = cardReferrals.where((r) => r.status == ReferralStatus.pending).toList();
    final validated = cardReferrals.where((r) => r.status == ReferralStatus.validated).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              title: t.referralTitle,
              actions: [NotificationBellButton(unreadCount: unreadNotifs)],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(referralProvider.notifier).loadMine(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.referralSubtitle,
                        style: AppTextStyles.bodyMedium(
                            color: AppColors.inkMuted(opacity: 0.65)),
                      ),
                      if (cards.length > 1) ...[
                        const SizedBox(height: 16),
                        SectionEyebrow(t.referralSelectEstablishment),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 68,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cards.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final card = cards[i];
                              final isSelected = card.id == selectedCard.id;
                              return _RestaurantSelectorChip(
                                card: card,
                                isSelected: isSelected,
                                onTap: () =>
                                    setState(() => _selectedCardId = card.id),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _QrCard(card: selectedCard, t: t, onShare: () => _share(selectedCard, t)),
                      const SizedBox(height: 24),
                      SectionEyebrow('${t.referralPendingTitle} (${pending.length})'),
                      const SizedBox(height: 8),
                      _ReferralList(
                        referrals: pending,
                        emptyMessage: t.referralPendingEmpty,
                        t: t,
                      ),
                      const SizedBox(height: 20),
                      SectionEyebrow('${t.referralValidatedTitle} (${validated.length})'),
                      const SizedBox(height: 8),
                      _ReferralList(
                        referrals: validated,
                        emptyMessage: t.referralValidatedEmpty,
                        t: t,
                      ),
                      const SizedBox(height: 20),
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

class _QrCard extends StatelessWidget {
  final LoyaltyCard card;
  final AppLocalizations t;
  final VoidCallback onShare;
  const _QrCard({required this.card, required this.t, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.resting,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: '$referralQrPrefix${card.referralQrToken}',
              size: 180,
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
          ),
          const SizedBox(height: 14),
          Text(t.referralYourCode.toUpperCase(),
              style: AppTextStyles.eyebrow(color: AppColors.inkMuted(opacity: 0.55))),
          const SizedBox(height: 4),
          Text(card.referralCode ?? '', style: AppTextStyles.monoLarge()),
          const SizedBox(height: 16),
          AppButton(
            label: t.referralShareButton,
            icon: LucideIcons.share2,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _ReferralList extends StatelessWidget {
  final List<Referral> referrals;
  final String emptyMessage;
  final AppLocalizations t;
  const _ReferralList({required this.referrals, required this.emptyMessage, required this.t});

  @override
  Widget build(BuildContext context) {
    if (referrals.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            emptyMessage,
            style: AppTextStyles.bodySmall(color: AppColors.inkMuted(opacity: 0.5)),
          ),
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (int i = 0; i < referrals.length; i++) ...[
            if (i > 0) Divider(height: 20, color: AppColors.border),
            _ReferralRow(referral: referrals[i], t: t),
          ],
        ],
      ),
    );
  }
}

class _ReferralRow extends StatelessWidget {
  final Referral referral;
  final AppLocalizations t;
  const _ReferralRow({required this.referral, required this.t});

  @override
  Widget build(BuildContext context) {
    final isValidated = referral.status == ReferralStatus.validated;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                referral.referredName,
                style: AppTextStyles.bodySmall().copyWith(fontWeight: FontWeight.w600),
              ),
              if (isValidated && referral.rewardTitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  t.referralRewardObtained(referral.rewardTitle!),
                  style: AppTextStyles.monoSmall(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(
          label: isValidated ? '✓' : '…',
          tone: isValidated ? StatusTone.success : StatusTone.neutral,
        ),
      ],
    );
  }
}

class _RestaurantSelectorChip extends StatelessWidget {
  final LoyaltyCard card;
  final bool isSelected;
  final VoidCallback onTap;

  const _RestaurantSelectorChip({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTapScale(
      onTap: onTap,
      scaleDown: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected ? null : AppShadows.resting,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.restaurantName,
              style: AppTextStyles.label(
                  color: isSelected ? Colors.white : AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              card.restaurantCategory,
              style: AppTextStyles.bodySmall(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.inkMuted(opacity: 0.55),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
