import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/core/theme/app_radius.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';

/// Sépare les milliers d'un nombre par un espace fine (ex. 12 400).
String formatGroupedNumber(int number) {
  final str = number.toString();
  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return str.replaceAllMapped(reg, (Match m) => '${m[1]} ');
}

/// Icône représentative de la catégorie affichée sur la carte —
/// heuristique sur le libellé (le modèle n'a pas de champ dédié),
/// suffisante pour le jeu de catégories actuel de l'app.
IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('monde')) return LucideIcons.globe;
  if (c.contains('gastronom')) return LucideIcons.wine;
  if (c.contains('cocktail') || c.contains('rooftop') || c.contains('bar')) {
    return LucideIcons.martini;
  }
  if (c.contains('brunch') ||
      c.contains('pâtisserie') ||
      c.contains('patisserie') ||
      c.contains('café') ||
      c.contains('cafe')) {
    return LucideIcons.coffee;
  }
  if (c.contains('bistrot') || c.contains('cuisine')) {
    return LucideIcons.utensils;
  }
  return LucideIcons.store;
}

/// Contenu d'une face de carte de fidélité — catégorie/ID, nom de
/// l'enseigne, puis bloc spécifique au mécanisme de fidélité
/// (tampons/points/cashback/VIP). Un seul point d'implémentation,
/// utilisé à la fois par [LoyaltyCardWidget] (pile du wallet, format
/// plein) et par l'écran de détail de carte (format compact) —
/// auparavant deux implémentations dupliquées.
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
    final subtextColor = textColor.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CardLogo(
                  logoUrl: card.logoUrl,
                  restaurantName: card.restaurantName,
                  textColor: textColor,
                  compact: compact,
                ),
                SizedBox(width: compact ? 8 : 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 7 : 10,
                          vertical: compact ? 3 : 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon(card.restaurantCategory),
                            size: compact ? 11 : 12,
                            color: textColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              card.restaurantCategory.toUpperCase(),
                              style:
                                  AppTextStyles.monoSmall(color: subtextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  card.fallbackId,
                  style: AppTextStyles.monoSmall(color: subtextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            SizedBox(height: compact ? 4 : 8),
            Text(
              card.restaurantName,
              style: AppTextStyles.displayLarge(color: textColor).copyWith(
                fontSize: compact ? 18 : 22,
                height: 1.05,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        _MechanicStat(card: card, textColor: textColor, subtextColor: subtextColor, compact: compact),
      ],
    );
  }
}

/// Logo de l'enseigne, en médaillon en tête de carte. Sans logo configuré
/// côté marchand (ou en cas d'échec de chargement), retombe sur un
/// monogramme — jamais sur l'icône de catégorie, déjà affichée dans le badge
/// juste à côté : les deux répétaient le même glyphe sur les boutiques sans
/// logo.
class _CardLogo extends StatelessWidget {
  final String? logoUrl;
  final String restaurantName;
  final Color textColor;
  final bool compact;

  const _CardLogo({
    required this.logoUrl,
    required this.restaurantName,
    required this.textColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 38.0;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14)),
          child: _content(size),
        ),
      ),
    );
  }

  Widget _content(double size) {
    if (logoUrl == null || logoUrl!.isEmpty) return _monogram(size);
    return CachedNetworkImage(
      imageUrl: logoUrl!,
      fit: BoxFit.cover,
      width: size,
      height: size,
      placeholder: (context, url) => _monogram(size),
      errorWidget: (context, url, error) => _monogram(size),
    );
  }

  Widget _monogram(double size) {
    final letter =
        restaurantName.trim().isNotEmpty ? restaurantName.trim()[0].toUpperCase() : '?';
    return Center(
      child: Text(
        letter,
        style: AppTextStyles.displayMedium(color: textColor).copyWith(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _MechanicStat extends StatelessWidget {
  final LoyaltyCard card;
  final Color textColor;
  final Color subtextColor;
  final bool compact;

  const _MechanicStat({
    required this.card,
    required this.textColor,
    required this.subtextColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (card.mechanic) {
      case LoyaltyMechanic.vip:
        return Row(
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                card.vipTier.label.toUpperCase(),
                style: AppTextStyles.monoSmall(color: textColor)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                card.vipTier == VipTier.platinum
                    ? t.cardVipMaxTier
                    : t.cardVipNextTier(
                        ((1 - card.vipProgressToNextTier) * 12).ceil()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall(color: subtextColor),
              ),
            ),
          ],
        );
      case LoyaltyMechanic.cashback:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _valueRow(
                t.cardCashbackLabel,
                formatGroupedNumber(card.cashbackBalanceFcfa),
                t.cardCashbackSuffix),
            _levelRow(),
          ],
        );
      case LoyaltyMechanic.points:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _valueRow(t.cardPointsLabel,
                formatGroupedNumber(card.pointsBalance), t.cardPointsSuffix),
            _levelRow(),
          ],
        );
      // Mode "Achat" : même compteur que "Points" côté données, mais un
      // libellé distinct (existait déjà dans l10n, jamais câblé) pour que
      // les deux mécaniques ne se ressemblent pas au premier coup d'œil.
      case LoyaltyMechanic.spend:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _valueRow(t.cardSpendLabel,
                formatGroupedNumber(card.pointsBalance), t.cardPointsSuffix,
                percent: card.percent),
            _levelRow(),
          ],
        );
      case LoyaltyMechanic.stamps:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _valueRow(t.cardStampsLabel,
                '${card.stampsCurrent}/${card.stampsGoal}', null,
                percent: card.percent),
            _levelRow(),
          ],
        );
    }
  }

  Widget _valueRow(String label, String value, String? suffix,
      {int? percent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.monoSmall(color: subtextColor)),
        SizedBox(height: compact ? 0 : 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.monoLarge(color: textColor).copyWith(
                  fontSize: compact ? 22 : 26,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 6),
              Text(suffix,
                  style: AppTextStyles.monoMedium(color: subtextColor)),
            ],
            if (percent != null) ...[
              const SizedBox(width: 6),
              Text('$percent%',
                  style: AppTextStyles.monoSmall(color: subtextColor)),
            ],
          ],
        ),
      ],
    );
  }

  /// Niveau de fidélité — indépendant du programme (Tampons/Achats/Cashback) :
  /// jamais le montant cumulé dépensé/gagné, uniquement le nom du niveau et
  /// le pourcentage vers le suivant, calculés côté serveur
  /// (`LoyaltyLevelService`).
  Widget _levelRow() {
    if (card.levelName == null) return const SizedBox.shrink();
    final currentTier =
        card.tiers.where((t) => t.status == 'reached').lastOrNull;
    final icon = currentTier?.icon;
    return Padding(
      padding: EdgeInsets.only(top: compact ? 2 : 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              card.isMaxLevel
                  ? '${card.levelName} · niveau maximum'
                  : '${card.levelName} · ${card.levelPercentToNext ?? 0}% vers le niveau suivant',
              style: AppTextStyles.monoSmall(color: subtextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
