import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:miva_fid/core/constants/referral_qr.dart';
import 'package:miva_fid/core/utils/toast_service.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_shadows.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/models/referral.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/referral_provider.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_section_header.dart';
import 'package:miva_fid/features/client/widgets/shared/notification_bell_button.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Écran de Parrainage épuré, clair et moderne — sans surcharge de cadres,
/// avec un padding inférieur adapté à la barre d'onglets et support complet clair/sombre.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key, this.initialCardId});
  final String? initialCardId;

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  String? _selectedCardId;
  int _selectedFilterIndex = 0; // 0: Tous, 1: En attente, 2: Validés

  @override
  void initState() {
    super.initState();
    _selectedCardId = widget.initialCardId;
  }

  @override
  void didUpdateWidget(covariant ReferralScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCardId != widget.initialCardId &&
        widget.initialCardId != null) {
      _selectedCardId = widget.initialCardId;
    }
  }

  void _share(LoyaltyCard card, AppLocalizations t) {
    Share.share(
      t.referralShareMessage(card.restaurantName, card.referralCode ?? ''),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ToastService.showSuccess('Code copié dans le presse-papier !');
  }

  void _showQrBottomSheet(BuildContext context, LoyaltyCard card) {
    final isDark = AppColors.isDark;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.inkMuted(opacity: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'QR Code de parrainage',
                style: AppTextStyles.titleMedium().copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.restaurantName,
                style: AppTextStyles.bodySmall(
                  color: AppColors.inkMuted(opacity: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.resting,
                ),
                child: QrImageView(
                  data: '$referralQrPrefix${card.referralQrToken}',
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1E293B),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Faites scanner ce QR code à votre proche pour qu\'il rejoigne ${card.restaurantName}.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall(
                  color: AppColors.inkMuted(opacity: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Fermer',
                variant: AppButtonVariant.outline,
                fullWidth: true,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
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
    final cardReferrals = referrals
        .where((r) => r.restaurantName == selectedCard.restaurantName)
        .toList();
    final pending = cardReferrals
        .where((r) => r.status == ReferralStatus.pending)
        .toList();
    final validated = cardReferrals
        .where((r) => r.status == ReferralStatus.validated)
        .toList();

    final displayedReferrals = switch (_selectedFilterIndex) {
      1 => pending,
      2 => validated,
      _ => cardReferrals,
    };

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
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceCard,
                onRefresh: () => ref.read(referralProvider.notifier).loadMine(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Padding inférieur pour laisser respirer l'écran
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sélecteur d'établissement compact si multiple
                      if (cards.length > 1) ...[
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cards.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final card = cards[i];
                              final isSelected = card.id == selectedCard.id;
                              return _EstablishmentChip(
                                card: card,
                                isSelected: isSelected,
                                onTap: () =>
                                    setState(() => _selectedCardId = card.id),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Carte Héroïque Parrainage — légère, aérée et sans cadres rigides
                      _HeroReferralCard(
                        card: selectedCard,
                        onCopy: () =>
                            _copyCode(selectedCard.referralCode ?? ''),
                        onShare: () => _share(selectedCard, t),
                        onShowQr: () =>
                            _showQrBottomSheet(context, selectedCard),
                      ),

                      const SizedBox(height: 14),

                      // Statistiques rapides
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'En attente',
                              count: pending.length,
                              icon: LucideIcons.hourglass,
                              iconColor: const Color(0xFFD97706),
                              bgColor: const Color(0xFFD97706)
                                  .withValues(alpha: 0.14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: 'Validés',
                              count: validated.length,
                              icon: LucideIcons.circleCheck,
                              iconColor: const Color(0xFF16A34A),
                              bgColor: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.14),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Titre & Filtre segmenté compact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SectionEyebrow(
                            'HISTORIQUE DES FILLEULS (${cardReferrals.length})',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _SegmentedFilterBar(
                        selectedIndex: _selectedFilterIndex,
                        counts: [
                          cardReferrals.length,
                          pending.length,
                          validated.length,
                        ],
                        onSelect: (index) =>
                            setState(() => _selectedFilterIndex = index),
                      ),
                      const SizedBox(height: 10),

                      // Liste des parrainages ouverte et épurée
                      if (displayedReferrals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 28),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _selectedFilterIndex == 2
                                      ? LucideIcons.gift
                                      : LucideIcons.users,
                                  size: 28,
                                  color: AppColors.inkMuted(opacity: 0.35),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedFilterIndex == 1
                                      ? t.referralPendingEmpty
                                      : _selectedFilterIndex == 2
                                          ? t.referralValidatedEmpty
                                          : 'Aucun filleul invité pour le moment.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodySmall(
                                    color: AppColors.inkMuted(opacity: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayedReferrals.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 1,
                            indent: 52,
                            endIndent: 8,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, i) {
                            final refItem = displayedReferrals[i];
                            return _ReferralListItem(
                              referral: refItem,
                              t: t,
                            );
                          },
                        ),
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

/// Carte Héroïque Parrainage — Simple, épurée et sans cadres superflus
class _HeroReferralCard extends StatelessWidget {
  final LoyaltyCard card;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onShowQr;

  const _HeroReferralCard({
    required this.card,
    required this.onCopy,
    required this.onShare,
    required this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Titre & établissement
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.gift,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitez vos proches',
                      style: AppTextStyles.titleMedium().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      card.restaurantName,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.inkMuted(opacity: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Mini étapes épurées (texte léger sans cadre lourd)
          const Row(
            children: [
              _MiniStep(number: '1', label: 'Partagez le code'),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: Color(0x59888888),
              ),
              _MiniStep(number: '2', label: '1ère visite'),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: Color(0x59888888),
              ),
              _MiniStep(number: '3', label: 'Cadeau débloqué'),
            ],
          ),

          const SizedBox(height: 14),

          // Ligne Code de Parrainage & Copie
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E232B)
                  : AppColors.primaryTint.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VOTRE CODE UNIQUE',
                        style: AppTextStyles.eyebrow(
                          color: AppColors.inkMuted(opacity: 0.6),
                        ).copyWith(fontSize: 9.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.referralCode ?? '---',
                        style: AppTextStyles.monoLarge().copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                AppTapScale(
                  onTap: onCopy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.copy, size: 13, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Copier',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Boutons d'action : Partager + Bouton QR Code adapté aux 2 thèmes
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Partager l\'invitation',
                  icon: LucideIcons.share2,
                  height: 44,
                  onTap: onShare,
                ),
              ),
              const SizedBox(width: 8),
              AppTapScale(
                onTap: onShowQr,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252A34)
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.qrCode,
                      size: 20,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
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

class _MiniStep extends StatelessWidget {
  final String number;
  final String label;

  const _MiniStep({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall(
                color: AppColors.inkMuted(opacity: 0.75),
              ).copyWith(fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: AppTextStyles.titleMedium().copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                title,
                style: AppTextStyles.bodySmall(
                  color: AppColors.inkMuted(opacity: 0.65),
                ).copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedFilterBar extends StatelessWidget {
  final int selectedIndex;
  final List<int> counts;
  final ValueChanged<int> onSelect;

  const _SegmentedFilterBar({
    required this.selectedIndex,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final titles = ['Tous', 'En attente', 'Validés'];
    final isDark = AppColors.isDark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232B) : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isSelected = selectedIndex == i;
          return Expanded(
            child: AppTapScale(
              onTap: () => onSelect(i),
              scaleDown: 0.98,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2C323D) : AppColors.surfaceCard)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected ? AppShadows.resting : null,
                ),
                child: Text(
                  '${titles[i]} (${counts[i]})',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.inkMuted(opacity: 0.7),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ReferralListItem extends StatelessWidget {
  final Referral referral;
  final AppLocalizations t;

  const _ReferralListItem({required this.referral, required this.t});

  @override
  Widget build(BuildContext context) {
    final isValidated = referral.status == ReferralStatus.validated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isValidated
                ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                : AppColors.surfaceMuted,
            child: Text(
              referral.referredName.isNotEmpty
                  ? referral.referredName[0].toUpperCase()
                  : 'F',
              style: TextStyle(
                color: isValidated
                    ? const Color(0xFF16A34A)
                    : AppColors.inkMuted(),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.referredName,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 1),
                if (isValidated && referral.rewardTitle != null)
                  Text(
                    t.referralRewardObtained(referral.rewardTitle!),
                    style: AppTextStyles.bodySmall(
                      color: const Color(0xFF16A34A),
                    ).copyWith(fontWeight: FontWeight.w500, fontSize: 11),
                  )
                else
                  Text(
                    'En attente du 1er passage',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.55),
                    ).copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
          StatusBadge(
            label: isValidated ? 'Validé' : 'En attente',
            tone: isValidated ? StatusTone.success : StatusTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _EstablishmentChip extends StatelessWidget {
  final LoyaltyCard card;
  final bool isSelected;
  final VoidCallback onTap;

  const _EstablishmentChip({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTapScale(
      onTap: onTap,
      scaleDown: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.store,
              size: 13,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              card.restaurantName,
              style: AppTextStyles.bodySmall().copyWith(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
