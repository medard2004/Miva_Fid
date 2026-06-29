import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/dashboard_stats_provider.dart';

class KpiPill extends StatelessWidget {
  const KpiPill({super.key, required this.data});
  final KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(right: Sp.sm),
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AnimatedCount(target: data.value),
          const SizedBox(height: 2),
          Text(data.label,
              style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({required this.target});
  final int target;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: 1500.ms,
      curve: Curves.easeOut,
      builder: (_, v, __) => Text(
        v.round().toString(),
        style: AppTextStyles.monoLg().copyWith(color: AppColors.primary),
      ),
    );
  }
}
