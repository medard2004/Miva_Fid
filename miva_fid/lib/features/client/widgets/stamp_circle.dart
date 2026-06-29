import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

class StampCircle extends StatelessWidget {
  const StampCircle({super.key, required this.filled, required this.index, this.size = 28});
  final bool filled;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        width: size, height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, color: AppColors.primary, size: size * 0.5),
      ).animate(delay: (index * 40).ms)
          .scale(begin: const Offset(0, 0), end: const Offset(1.15, 1.15),
              curve: Curves.elasticOut, duration: 400.ms)
          .then()
          .scale(end: const Offset(1.0, 1.0), duration: 100.ms);
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
    );
  }
}
