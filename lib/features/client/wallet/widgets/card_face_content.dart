import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/core/theme/app_radius.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'stamp_grid.dart';

/// Sépare les milliers d'un nombre par un espace fine (ex. 12 400).
String formatGroupedNumber(int number) {
  final str = number.toString();
  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return str.replaceAllMapped(reg, (Match m) => '${m[1]} ');
}

/// Icône représentative de la catégorie affichée sur la carte.
IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('spa') || c.contains('massage') || c.contains('bien-être')) {
    return LucideIcons.sparkles;
  }
  if (c.contains('coiff') ||
      c.contains('beauté') ||
      c.contains('beaute') ||
      c.contains('salon') ||
      c.contains('barber')) {
    return LucideIcons.scissors;
  }
  if (c.contains('hôt') || c.contains('hot') || c.contains('héberg')) {
    return LucideIcons.bedDouble;
  }
  if (c.contains('monde')) return LucideIcons.globe;
  if (c.contains('gastronom') || c.contains('vin')) return LucideIcons.wine;
  if (c.contains('cocktail') || c.contains('rooftop') || c.contains('bar')) {
    return LucideIcons.martini;
  }
  if (c.contains('brunch') ||
      c.contains('pâtisserie') ||
      c.contains('patisserie') ||
      c.contains('café') ||
      c.contains('cafe') ||
      c.contains('boulang')) {
    return LucideIcons.coffee;
  }
  if (c.contains('bistrot') ||
      c.contains('cuisine') ||
      c.contains('restaurant') ||
      c.contains('food')) {
    return LucideIcons.utensils;
  }
  if (c.contains('parfum') || c.contains('cosmét')) {
    return LucideIcons.sparkles;
  }
  if (c.contains('boutique') ||
      c.contains('mode') ||
      c.contains('prêt-à-porter')) {
    return LucideIcons.shoppingBag;
  }
  if (c.contains('pharmacie') || c.contains('santé')) {
    return LucideIcons.pill;
  }
  if (c.contains('supérette') ||
      c.contains('supermarché') ||
      c.contains('epicerie')) {
    return LucideIcons.shoppingCart;
  }
  return LucideIcons.store;
}

/// Contenu d'une face de carte de fidélité — identique au design de l'onboarding
/// marchand (badge catégorie en haut à gauche, médaillon logo à droite,
/// nom en Cormorant, bloc mécanique et barre de progression en bas).
class CardFaceContent extends StatelessWidget {
  final LoyaltyCard card;
  final Color textColor;
  final bool compact;

  const CardFaceContent({
    super.key,
    required this.card,
    required this.textColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CardTopGroup(
          card: card,
          textColor: textColor,
          compact: compact,
        ),
        _CardBottomGroup(
          card: card,
          textColor: textColor,
          compact: compact,
        ),
      ],
    );
  }
}

/// Haut de la carte : Pill catégorie (gauche) + Logo circulaire (droite) + Nom
class _CardTopGroup extends StatelessWidget {
  final LoyaltyCard card;
  final Color textColor;
  final bool compact;

  const _CardTopGroup({
    required this.card,
    required this.textColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = card.logoUrl != null && card.logoUrl!.isNotEmpty;
    final catIcon = categoryIcon(card.restaurantCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(catIcon, size: 10, color: Colors.white),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      (card.restaurantCategory.isEmpty
                              ? 'Commerce'
                              : card.restaurantCategory)
                          .toUpperCase(),
                      style: AppTextStyles.monoSmall(
                              color: Colors.white.withValues(alpha: 0.85))
                          .copyWith(
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (hasLogo)
              CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: card.logoUrl!,
                    width: 22,
                    height: 22,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(
                      catIcon,
                      size: 13,
                      color: card.liningColor,
                    ),
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Icon(catIcon, size: 13, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          card.restaurantName.isEmpty ? 'Votre Commerce' : card.restaurantName,
          style: AppTextStyles.displayLarge(color: Colors.white).copyWith(
            fontSize: compact ? 17 : 19,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Bas de la carte : Métriques (Tampons / Achats / Points / Cashback / VIP)
class _CardBottomGroup extends StatelessWidget {
  final LoyaltyCard card;
  final Color textColor;
  final bool compact;

  const _CardBottomGroup({
    required this.card,
    required this.textColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    switch (card.mechanic) {
      case LoyaltyMechanic.stamps:
        return _buildStamps();
      case LoyaltyMechanic.cashback:
        return _buildCashback();
      case LoyaltyMechanic.spend:
      case LoyaltyMechanic.points:
        return _buildSpendOrPoints();
      case LoyaltyMechanic.vip:
        return _buildVip();
    }
  }

  Widget _buildStamps() {
    final safeGoal = card.stampsGoal > 0 ? card.stampsGoal : 10;
    final progress = (card.stampsCurrent / safeGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TAMPONS',
          style: AppTextStyles.monoSmall(
                  color: Colors.white.withValues(alpha: 0.7))
              .copyWith(
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${card.stampsCurrent}/$safeGoal',
          style: AppTextStyles.monoLarge(color: Colors.white).copyWith(
            fontSize: 18,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        StampGrid(
          filled: card.stampsCurrent,
          total: safeGoal,
          stampSize: 14,
          gap: 4,
          designType: card.stampDesignType,
          emoji: card.stampEmoji,
          iconName: card.stampIcon,
          textColor: Colors.white,
          cardColor: card.liningColor,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCashback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(LucideIcons.wallet,
                size: 10, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              'CASHBACK',
              style: AppTextStyles.monoSmall(
                      color: Colors.white.withValues(alpha: 0.7))
                  .copyWith(
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${formatGroupedNumber(card.cashbackBalanceFcfa)} FCFA',
          style: AppTextStyles.monoLarge(color: Colors.white).copyWith(
            fontSize: 18,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Solde utilisable en réduction, crédité à chaque achat',
          style: AppTextStyles.caption(
                  color: Colors.white.withValues(alpha: 0.75))
              .copyWith(
            fontSize: 10.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSpendOrPoints() {
    final isSpend = card.mechanic == LoyaltyMechanic.spend;
    final mechanicIcon = isSpend ? LucideIcons.shoppingBag : LucideIcons.coins;
    final safeGoal = card.stampsGoal > 0 ? card.stampsGoal : 100;
    final remaining = (safeGoal - card.pointsBalance).clamp(0, 999999);
    final rewardDesc = card.nextReward?.rewardDescription ?? '';
    final progress = (card.pointsBalance / safeGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(mechanicIcon,
                size: 10, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              isSpend ? 'ACHATS' : 'POINTS',
              style: AppTextStyles.monoSmall(
                      color: Colors.white.withValues(alpha: 0.7))
                  .copyWith(
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${card.pointsBalance}',
              style: AppTextStyles.monoLarge(color: Colors.white).copyWith(
                fontSize: 18,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isSpend ? 'pts' : 'points',
              style: AppTextStyles.monoSmall(
                      color: Colors.white.withValues(alpha: 0.7))
                  .copyWith(
                fontSize: 11,
              ),
            ),
            const Spacer(),
            if (card.stampsGoal > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mechanicIcon,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Objectif : ${card.stampsGoal} pts',
                      style: AppTextStyles.caption(color: Colors.white).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          remaining > 0
              ? 'Encore $remaining pour : ${rewardDesc.isEmpty ? "votre récompense" : rewardDesc}'
              : (rewardDesc.isNotEmpty ? rewardDesc : 'Objectif atteint !'),
          style: AppTextStyles.caption(
                  color: Colors.white.withValues(alpha: 0.75))
              .copyWith(
            fontSize: 10.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildVip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(LucideIcons.crown,
                size: 10, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              'STATUT VIP',
              style: AppTextStyles.monoSmall(
                      color: Colors.white.withValues(alpha: 0.7))
                  .copyWith(
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          card.vipTier.label.toUpperCase(),
          style: AppTextStyles.monoLarge(color: Colors.white).copyWith(
            fontSize: 18,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          card.vipTier == VipTier.platinum
              ? 'Avantages exclusifs VIP Platinum'
              : 'Encore ${((1 - card.vipProgressToNextTier) * 12).ceil()} visites vers le rang suivant',
          style: AppTextStyles.caption(
                  color: Colors.white.withValues(alpha: 0.75))
              .copyWith(
            fontSize: 10.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
