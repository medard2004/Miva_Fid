import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/loyalty_card_model.dart';

class ClientRow extends StatelessWidget {
  const ClientRow({
    super.key,
    required this.card,
    this.onTap,
    this.stampsRequired = 10,
    this.onViewDetail,
    this.onSendMessage,
  });

  final LoyaltyCardModel card;
  final VoidCallback? onTap;
  final int stampsRequired;
  final VoidCallback? onViewDetail;
  final VoidCallback? onSendMessage;

  @override
  Widget build(BuildContext context) {
    final name = card.client?.name ?? 'Client';
    final phone = card.client?.phone ?? '+228 90 00 00 00';
    final initials = card.client?.initials ?? '?';
    final int hash = name.hashCode;

    // Niveau de fidélité réel (`LoyaltyLevelService` côté API) — `null` tant
    // que le programme n'a pas encore résolu de niveau pour cette carte.
    final tier = card.levelName;
    final (badgeBg, badgeFg) = _levelColors(tier);

    // Determine deterministic last visit time
    final String visitTime;
    final int timeIdx = hash.abs() % 5;
    if (timeIdx == 0) {
      visitTime = 'il y a 2h';
    } else if (timeIdx == 1) {
      visitTime = 'il y a 3h';
    } else if (timeIdx == 2) {
      visitTime = 'hier';
    } else if (timeIdx == 3) {
      visitTime = 'il y a 2j';
    } else {
      visitTime = 'il y a 5j';
    }

    // Determine avatar background color
    final avatarColors = [
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFF1592A), // Orange/yellow-red
      const Color(0xFF0EA5E9), // Cyan
      const Color(0xFF10B981), // Green
    ];
    final avatarBg = avatarColors[hash.abs() % avatarColors.length];

    final progress = (card.stampsCount / stampsRequired).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: Rd.card,
      child: Container(
        margin: const EdgeInsets.only(bottom: Sp.sm),
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Rd.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar, Name + Info, Quick Action Buttons
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarBg,
                  child: Text(
                    initials,
                    style: AppTextStyles.mono().copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              name, 
                              style: AppTextStyles.labelBold(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tier != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tier,
                                style: AppTextStyles.caption().copyWith(
                                  color: badgeFg,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$phone • $visitTime',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick Action Buttons
                _QuickActionBtn(
                  icon: LucideIcons.messageCircle,
                  onTap: onSendMessage,
                ),
              ],
            ),
            const SizedBox(height: Sp.md),
            // Row 2: Stamp progress indicator bar & numerical indicator
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 6,
                    child: ClipRRect(
                      borderRadius: Rd.pill,
                      child: LinearProgressIndicator(
                        value: progress,
                        color: AppColors.merchant,
                        backgroundColor: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Sp.md),
                Text(
                  '${card.stampsCount}/$stampsRequired',
                  style: AppTextStyles.mono().copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Couleurs du badge de niveau — reconnaît les noms par défaut
  /// (Bronze/Argent/Or/Platine, insensible à la casse/aux accents anglais)
  /// et retombe sur une teinte neutre pour un nom personnalisé par le
  /// marchand (`programme_screen.dart` permet de renommer les niveaux).
  (Color, Color) _levelColors(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('or') || n.contains('gold')) {
      return (AppColors.warningTint, AppColors.warningDark);
    }
    if (n.contains('argent') || n.contains('silver')) {
      return (AppColors.border, AppColors.textSecondary);
    }
    if (n.contains('platine') || n.contains('platinum')) {
      return (AppColors.merchantTint, AppColors.merchant);
    }
    if (n.contains('bronze')) {
      return (AppColors.dangerTint, AppColors.warningDark);
    }
    return (AppColors.merchantTint, AppColors.merchant);
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.border,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 16,
        ),
      ),
    );
  }
}

