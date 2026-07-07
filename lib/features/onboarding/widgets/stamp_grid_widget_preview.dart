import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StampGridWidgetPreview extends StatelessWidget {
  const StampGridWidgetPreview({
    super.key,
    required this.filled,
    required this.total,
    this.stampSize = 26,
    this.gap = 6,
  });

  final int filled;
  final int total;
  final double stampSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final clampedFilled = filled.clamp(0, total);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: List.generate(total, (i) {
        final isFilled = i < clampedFilled;
        if (isFilled) {
          return Container(
            width: stampSize,
            height: stampSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.transparent,
              size: stampSize * 0.5,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1.15, 1.15),
                curve: Curves.elasticOut,
                duration: 400.ms,
                delay: (i * 40).ms,
              )
              .then()
              .scale(
                end: const Offset(1.0, 1.0),
                duration: 100.ms,
              );
        }
        return Container(
          width: stampSize,
          height: stampSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}
