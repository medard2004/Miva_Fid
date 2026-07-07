import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/dashboard_stats_provider.dart';

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.item});
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final int hash = item.clientName.hashCode;
    
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

    // Determine stamps progress or reward status
    final bool isReward = item.action.toLowerCase().contains('récompense') || (hash % 5 == 0);
    final String valueText = isReward ? '10/10' : '${(hash % 7) + 2}/10';

    // Avatar color
    final avatarColors = [
      (const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
      (const Color(0xFFECFDF5), const Color(0xFF059669)),
      (const Color(0xFFFDF2F8), const Color(0xFFDB2777)),
      (const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
    ];
    final avatarColorPair = avatarColors[hash % avatarColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColorPair.$1,
            child: Text(
              item.initials,
              style: AppTextStyles.mono().copyWith(
                color: avatarColorPair.$2,
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
                  children: [
                    Text(item.clientName, style: AppTextStyles.labelBold()),
                    const SizedBox(width: Sp.xs),
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
                  isReward ? 'Récompense utilisée • ${item.time}' : 'Tampon validé • ${item.time}',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                valueText,
                style: AppTextStyles.labelBold().copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (isReward) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 14,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
