import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StampGridWidgetPreview extends StatelessWidget {
  const StampGridWidgetPreview({
    super.key,
    required this.filled,
    required this.total,
    this.stampSize = 26,
    this.gap = 6,
    this.designType = 'check',
    this.emoji = '✨',
    this.iconName = 'check_rounded',
    required this.primaryColor,
  });

  final int filled;
  final int total;
  final double stampSize;
  final double gap;
  final String designType;
  final String emoji;
  final String iconName;
  final Color primaryColor;

  IconData _getIconData(String name) {
    switch (name) {
      case 'star_rounded':
        return Icons.star_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      case 'local_cafe_rounded':
        return Icons.local_cafe_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'auto_awesome_rounded':
        return Icons.auto_awesome_rounded;
      case 'emoji_emotions_rounded':
        return Icons.emoji_emotions_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      case 'check_rounded':
      default:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clampedFilled = filled.clamp(0, total);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: List.generate(total, (i) {
        final isFilled = i < clampedFilled;
        if (isFilled) {
          Widget child;
          if (designType == 'emoji') {
            child = Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: stampSize * 0.55),
              ),
            );
          } else if (designType == 'icon') {
            child = Center(
              child: Icon(
                _getIconData(iconName),
                color: primaryColor,
                size: stampSize * 0.55,
              ),
            );
          } else {
            child = Center(
              child: Icon(
                Icons.check_rounded,
                color: primaryColor,
                size: stampSize * 0.55,
              ),
            );
          }

          return Container(
            width: stampSize,
            height: stampSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: child,
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
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

