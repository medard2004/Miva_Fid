import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';

class StampStepper extends StatelessWidget {
  const StampStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 3,
    this.max = 50,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: Rd.card,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepperBtn(
                icon: Icons.remove,
                onTap: value > min
                    ? () {
                        AppHaptics.selection();
                        onChanged(value - 1);
                      }
                    : null,
              ),
              Text(
                value.toString(),
                style: AppTextStyles.monoXl().copyWith(color: AppColors.primary),
              ),
              _StepperBtn(
                icon: Icons.add,
                onTap: value < max
                    ? () {
                        AppHaptics.selection();
                        onChanged(value + 1);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.xs),
        Text(
          'tampons pour une récompense',
          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryTint : AppColors.bgLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
