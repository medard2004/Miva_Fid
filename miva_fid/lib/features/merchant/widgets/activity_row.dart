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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryTint,
            child: Text(item.initials,
                style: AppTextStyles.mono().copyWith(
                    color: AppColors.primary, fontSize: 12)),
          ),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.clientName, style: AppTextStyles.labelBold()),
                Text(item.action,
                    style: AppTextStyles.caption()
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(item.time,
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
