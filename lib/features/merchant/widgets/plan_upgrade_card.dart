import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/gen/app_localizations.dart';

class PlanUpgradeCard extends StatelessWidget {
  const PlanUpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
              Text(t.merchantPlanUpgradeTitle, style: AppTextStyles.labelBold().copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: Sp.xs),
          Text(t.merchantPlanUpgradeSubtitle,
              style: AppTextStyles.caption().copyWith(color: Colors.white70)),
          const SizedBox(height: Sp.md),
          AppButton.custom(t.merchantPlanUpgradeButton,
              backgroundColor: Colors.white,
              textColor: AppColors.merchant,
              icon: LucideIcons.arrowRight,
              onPressed: () => AppToast.info(context, t.merchantPlanUpgradeToast)),
        ],
      ),
    );
  }
}
