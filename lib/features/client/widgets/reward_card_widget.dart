import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/reward_model.dart';

class RewardCardWidget extends StatelessWidget {
  const RewardCardWidget({super.key, required this.reward, this.onTap});
  final RewardModel reward;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isUsed = reward.isUsed;
    final isExpired = reward.isExpired;
    final color = isUsed || isExpired ? AppColors.textSecondary : AppColors.primary;

    return GestureDetector(
      onTap: isUsed || isExpired ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Sp.sm),
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: isUsed || isExpired ? AppColors.bgLight : Colors.white,
          borderRadius: Rd.card,
          border: Border.all(color: isUsed || isExpired ? AppColors.border : color.withOpacity(0.3), width: 1.5),
          boxShadow: isUsed || isExpired ? [] : [BoxShadow(
              color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(
                  color: isUsed || isExpired ? AppColors.border : AppColors.primaryTint,
                  borderRadius: Rd.button),
              child: Icon(Icons.card_giftcard_rounded,
                  color: isUsed || isExpired ? AppColors.textSecondary : AppColors.primary, size: 24),
            ),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Récompense débloquée',
                      style: AppTextStyles.labelBold().copyWith(
                          color: isUsed || isExpired ? AppColors.textSecondary : AppColors.textPrimary)),
                  if (reward.expiresAt != null)
                    Text(isExpired ? 'Expirée' : 'Expire ${DateFormatter.relative(reward.expiresAt!)}',
                        style: AppTextStyles.caption().copyWith(
                            color: isExpired ? AppColors.danger : AppColors.textSecondary)),
                  if (isUsed) Text('Utilisée', style: AppTextStyles.caption().copyWith(color: AppColors.success)),
                ],
              ),
            ),
            if (!isUsed && !isExpired)
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
