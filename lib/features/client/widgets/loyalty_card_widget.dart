import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../models/loyalty_card_model.dart';
import '../../merchant/widgets/stamp_grid_widget.dart';

class LoyaltyCardWidget extends StatelessWidget {
  const LoyaltyCardWidget.featured({super.key, required this.card})
      : compact = false;
  const LoyaltyCardWidget.compact({super.key, required this.card})
      : compact = true;

  final LoyaltyCardModel card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final merchant = card.merchant;
    final primary = merchant?.primaryColor ?? AppColors.primary;
    final secondary = merchant?.secondaryColor ?? AppColors.primaryDark;
    final required = merchant?.stampsRequired ?? 10;
    final progress = card.progressRatio(required);
    final remaining = card.stampsRemaining(required);

    if (compact) {
      return Container(
        width: 160,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: Rd.card,
          gradient: LinearGradient(
            colors: [primary, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(Sp.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(merchant?.name ?? '', style: AppTextStyles.caption().copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text('${card.stampsCount}/$required tampons',
                style: AppTextStyles.mono().copyWith(color: Colors.white, fontSize: 11)),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: Rd.pill,
              child: LinearProgressIndicator(value: progress, color: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3), minHeight: 3)),
          ],
        ),
      );
    }

    return Container(
      height: 196,
      decoration: BoxDecoration(
        borderRadius: Rd.card20,
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: Colors.white,
                    child: Text(merchant?.initials ?? '?',
                        style: AppTextStyles.mono().copyWith(color: primary, fontSize: 12, fontWeight: FontWeight.w700))),
                const SizedBox(width: Sp.sm),
                Expanded(child: Text(merchant?.name ?? '', style: AppTextStyles.labelBold().copyWith(color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (merchant != null)
                  AppBadge(merchant.category,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      textColor: Colors.white),
              ],
            ),
            const SizedBox(height: Sp.sm),
            StampGridWidget(filled: card.stampsCount, total: required, stampSize: 26, gap: 8),
            const SizedBox(height: Sp.xs),
            Text('${card.stampsCount} sur $required — encore $remaining visite${remaining > 1 ? "s" : ""}',
                style: AppTextStyles.caption().copyWith(color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: Sp.xs),
            ClipRRect(borderRadius: Rd.pill,
              child: LinearProgressIndicator(value: progress, color: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3), minHeight: 3)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}
