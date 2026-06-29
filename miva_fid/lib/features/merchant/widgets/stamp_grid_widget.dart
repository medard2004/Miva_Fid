import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

class StampGridWidget extends StatelessWidget {
  const StampGridWidget({
    super.key,
    required this.filled,
    required this.total,
    this.stampSize = 28,
    this.gap = 6,
    this.animate = false,
  });

  final int filled;
  final int total;
  final double stampSize;
  final double gap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final clampedFilled = filled.clamp(0, total);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: List.generate(total, (i) {
        final isFilled = i < clampedFilled;
        Widget stamp = Container(
          width: stampSize,
          height: stampSize,
          decoration: BoxDecoration(
            color: isFilled ? AppColors.primaryTint : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isFilled ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: isFilled
              ? Icon(Icons.check_rounded, color: AppColors.primary, size: stampSize * 0.5)
              : null,
        );
        if (animate && isFilled) {
          stamp = stamp
              .animate(delay: (i * 40).ms)
              .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1.15, 1.15),
                  curve: Curves.elasticOut,
                  duration: 400.ms)
              .then()
              .scale(end: const Offset(1.0, 1.0), duration: 100.ms);
        }
        return stamp;
      }),
    );
  }
}
