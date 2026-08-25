import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.current,
    this.total = 4,
    this.stepTitle,
    this.onBack,
    this.showBackButton,
  });

  final int current;
  final int total;
  final String? stepTitle;
  final VoidCallback? onBack;
  final bool? showBackButton;

  String _defaultTitle(int step) {
    switch (step) {
      case 1:
        return 'Votre commerce';
      case 2:
        return 'Localisation';
      case 3:
        return 'Votre programme';
      case 4:
        return 'Design de la carte';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveShowBack = showBackButton ?? (current > 1);
    final title = stepTitle ?? _defaultTitle(current);
    final percent = ((current / total) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (effectiveShowBack)
                InkWell(
                  onTap: onBack ?? () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      if (current == 2) context.go('/auth/merchant/step1');
                      if (current == 3) context.go('/auth/merchant/location');
                      if (current == 4) context.go('/auth/merchant/step2');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.merchant.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 18,
                    color: AppColors.merchant,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.merchant.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ÉTAPE $current/$total',
                            style: const TextStyle(
                              color: AppColors.merchant,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelBold().copyWith(
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.merchant,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 4 segmented rounded progress bars
          Row(
            children: List.generate(total, (index) {
              final isFilled = index <= current - 1;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isFilled ? AppColors.merchant : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
