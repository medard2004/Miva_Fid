import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/loyalty_card_model.dart';
import 'stamp_grid_widget.dart';

class ClientCardSheet extends StatelessWidget {
  const ClientCardSheet({
    super.key,
    required this.card,
    required this.stampsRequired,
    required this.onValidate,
  });

  final LoyaltyCardModel card;
  final int stampsRequired;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final name = card.client?.name ?? 'Client';
    final phone = card.client?.phone ?? '';
    final initials = card.client?.initials ?? '?';
    final since = DateFormatter.memberSince(card.createdAt);
    final progress = card.progressRatio(stampsRequired);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryTint,
                      child: Text(initials,
                          style: AppTextStyles.mono()
                              .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.labelBold()),
                          if (phone.isNotEmpty)
                            Text(phone,
                                style: AppTextStyles.caption()
                                    .copyWith(color: AppColors.textSecondary)),
                          Text(since,
                              style: AppTextStyles.caption()
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: Sp.lg),
                StampGridWidget(
                  filled: card.stampsCount,
                  total: stampsRequired,
                  stampSize: 28,
                  primaryColor: AppColors.primary,
                ),
                const SizedBox(height: Sp.sm),
                Text('${card.stampsCount} sur $stampsRequired tampons',
                    style: AppTextStyles.caption()
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: Sp.xs),
                ClipRRect(
                  borderRadius: Rd.pill,
                  child: LinearProgressIndicator(
                    value: progress,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: Sp.lg),
                AppButton.primary('Valider l\'achat',
                    onPressed: () {
                      Navigator.pop(context);
                      onValidate();
                    }),
                const SizedBox(height: Sp.sm),
                AppButton.ghost('Annuler', onPressed: () => Navigator.pop(context)),
                SizedBox(height: MediaQuery.of(context).padding.bottom + Sp.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
