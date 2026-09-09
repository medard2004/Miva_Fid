import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/dashboard_stats_provider.dart';

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.item});
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final int hash = item.clientName.hashCode;

    // Determine tier & colors
    final String tier;
    final Color badgeBg;
    final Color badgeFg;
    if (hash % 3 == 0) {
      tier = t.merchantTierGold;
      badgeBg = AppColors.warningTint;
      badgeFg = AppColors.warningDark;
    } else if (hash % 3 == 1) {
      tier = t.merchantTierSilver;
      badgeBg = AppColors.border;
      badgeFg = AppColors.textSecondary;
    } else {
      tier = t.merchantTierPlatinum;
      badgeBg = AppColors.merchantTint;
      badgeFg = AppColors.merchant;
    }

    // Determine stamps progress or reward status
    final bool isReward = item.action.toLowerCase().contains('récompense') || (hash % 5 == 0);
    final String valueText = isReward ? '10/10' : '${(hash % 7) + 2}/10';

    // Avatar color — fonds pastel en clair, remplacés par un fond assombri
    // de même teinte en sombre (cf. AppColors.primaryTint et consorts).
    final avatarColors = [
      (AppColors.primaryTint, const Color(0xFF4F46E5)),
      (AppColors.isDark ? const Color(0xFF122A22) : const Color(0xFFECFDF5), const Color(0xFF059669)),
      (AppColors.isDark ? const Color(0xFF2E1626) : const Color(0xFFFDF2F8), const Color(0xFFDB2777)),
      (AppColors.isDark ? const Color(0xFF2E2013) : const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
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
                  isReward
                      ? '${t.merchantClientDetailHistoryRewardUsed} • ${item.time}'
                      : '${t.merchantClientDetailHistoryStampValidated} • ${item.time}',
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
                  LucideIcons.circleCheck,
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
