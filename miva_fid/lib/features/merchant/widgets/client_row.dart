import 'package:flutter/material.dart';

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

    // Determine tier & colors
    final String tier;
    final Color badgeBg;
    final Color badgeFg;
    if (hash % 3 == 0) {
      tier = 'Or';
      badgeBg = const Color(0xFFFEF3C7);
      badgeFg = const Color(0xFFD97706);
    } else if (hash % 3 == 1) {
      tier = 'Argent';
      badgeBg = const Color(0xFFF3F4F6);
      badgeFg = const Color(0xFF4B5563);
    } else {
      tier = 'Platine';
      badgeBg = const Color(0xFFF3E8FF);
      badgeFg = const Color(0xFF7C3AED);
    }

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
          color: Colors.white,
          borderRadius: Rd.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.03),
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
                          Text(name, style: AppTextStyles.labelBold()),
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
                  icon: Icons.visibility_outlined,
                  onTap: onViewDetail ?? onTap,
                ),
                const SizedBox(width: 8),
                _QuickActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
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
                        backgroundColor: AppColors.border.withOpacity(0.5),
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
          color: const Color(0xFFF3F4F6),
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

