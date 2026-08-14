import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';

class PlanUpgradeCard extends StatelessWidget {
  const PlanUpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.merchant, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Rd.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.award, color: AppColors.warning, size: 20),
              const SizedBox(width: Sp.xs),
              Text('Passez à Pro', style: AppTextStyles.labelBold().copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: Sp.xs),
          Text('Campagnes SMS illimitées, analytics avancés et support prioritaire.',
              style: AppTextStyles.caption().copyWith(color: Colors.white70)),
          const SizedBox(height: Sp.md),
          AppButton.custom('Découvrir Pro',
              backgroundColor: Colors.white,
              textColor: AppColors.merchant,
              icon: LucideIcons.arrowRight,
              onPressed: () => AppToast.info(context, 'Offre Pro bientôt disponible')),
        ],
      ),
    );
  }
}
