import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Animation d'apparition rapide (remplace les anciens squelettes).
class FastAppear extends StatelessWidget {
  const FastAppear({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 160),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.015,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Écran de transition neutre sans chargement circulaire bloquant.
class BootAppearScreen extends StatelessWidget {
  const BootAppearScreen({super.key, this.isMerchant = false});

  final bool isMerchant;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.height = 48,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.45),
          borderRadius: borderRadius ?? Rd.card,
        ),
      ).animate().fadeIn(duration: 140.ms, curve: Curves.easeOut),
    );
  }
}
