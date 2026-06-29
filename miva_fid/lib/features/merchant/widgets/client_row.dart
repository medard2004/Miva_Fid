import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/loyalty_card_model.dart';

class ClientRow extends StatelessWidget {
  const ClientRow({super.key, required this.card, this.onTap, this.stampsRequired = 10});
  final LoyaltyCardModel card;
  final VoidCallback? onTap;
  final int stampsRequired;

  static const _colors = [
    Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF0891B2),
    Color(0xFF16A34A), Color(0xFFDC2626), Color(0xFFD97706),
  ];

  Color _colorForName(String name) {
    if (name.isEmpty) return _colors[0];
    return _colors[name.codeUnitAt(0) % _colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = card.client?.name ?? 'Client';
    final phone = card.client?.phone ?? '';
    final initials = card.client?.initials ?? '?';
    final color = _colorForName(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Sp.sm),
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: Rd.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.15),
              child: Text(initials,
                  style: AppTextStyles.mono().copyWith(color: color, fontWeight: FontWeight.w700)),
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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 64,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: Rd.pill,
                    child: LinearProgressIndicator(
                      value: (card.stampsCount / stampsRequired).clamp(0.0, 1.0),
                      color: AppColors.primary,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${card.stampsCount}/$stampsRequired',
                    style: AppTextStyles.mono()
                        .copyWith(fontSize: 12, color: AppColors.primary)),
              ],
            ),
            const SizedBox(width: Sp.xs),
            const Icon(Icons.chevron_right_rounded, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}
