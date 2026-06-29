import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';
import 'stamp_grid_widget_preview.dart';

class LoyaltyCardPreview extends ConsumerWidget {
  const LoyaltyCardPreview({super.key, this.previewStamps = 7});

  final int previewStamps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);

    final primary = state.colorPrimary;
    final secondary = HSLColor.fromColor(primary)
        .withLightness(
          (HSLColor.fromColor(primary).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();

    final progress = previewStamps / state.stampsRequired;
    final remaining = state.stampsRequired - previewStamps;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 188,
      decoration: BoxDecoration(
        borderRadius: Rd.card20,
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(
                    _iconForType(state.commerceType),
                    size: 18,
                    color: primary,
                  ),
                ),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.commerceName.isEmpty
                            ? 'Votre Commerce'
                            : state.commerceName,
                        style: AppTextStyles.labelBold().copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        state.commerceType.isEmpty
                            ? 'Commerce'
                            : state.commerceType,
                        style: AppTextStyles.caption().copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.sm),
            StampGridWidgetPreview(
              filled: previewStamps,
              total: state.stampsRequired,
              stampSize: 26,
            ),
            const SizedBox(height: Sp.xs),
            Text(
              '$previewStamps sur ${state.stampsRequired} — encore $remaining pour votre récompense',
              style: AppTextStyles.caption().copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: Sp.xs),
            ClipRRect(
              borderRadius: Rd.pill,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                color: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.3),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1.0, 1.0),
          duration: 150.ms,
        );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Restaurant':
        return Icons.restaurant_outlined;
      case 'Hôtel':
        return Icons.hotel_outlined;
      case 'Salon':
        return Icons.content_cut_outlined;
      case 'Boutique':
        return Icons.shopping_bag_outlined;
      case 'Café':
        return Icons.coffee_outlined;
      default:
        return Icons.store_outlined;
    }
  }
}
