import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../client/providers/settings_provider.dart';

class OnboardingProgressBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final effectiveShowBack = showBackButton ?? (current > 1);
    final title = stepTitle ?? _defaultTitle(current);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Clean back arrow (no frame / border)
              if (effectiveShowBack)
                IconButton(
                  onPressed: onBack ?? () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      if (current == 2) context.go('/auth/merchant/step1');
                      if (current == 3) context.go('/auth/merchant/location');
                      if (current == 4) context.go('/auth/merchant/step2');
                    }
                  },
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              else
                const SizedBox(width: 40),

              // Centered Step Title
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelBold().copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // Placeholder to balance the left back arrow
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),

          // Segmented progress indicator bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: List.generate(total, (index) {
                final isFilled = index <= current - 1;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3.5,
                    margin: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isFilled ? AppColors.merchant : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
