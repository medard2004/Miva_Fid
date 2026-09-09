import 'package:flutter/material.dart';

import '../../../core/domain/tier_icon_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Sélecteur d'icône pour un palier au-delà du 5ᵉ (voir `TierEditorForm` —
/// les 5 premiers ont une icône fixe, non modifiable).
Future<String?> showTierIconPickerSheet(BuildContext context, String? currentKey) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisir une icône', style: AppTextStyles.labelBold()),
            const SizedBox(height: Sp.md),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Sp.sm,
              crossAxisSpacing: Sp.sm,
              children: [
                for (final option in TierIconPalette.options)
                  _IconTile(
                    option: option,
                    selected: option.key == currentKey,
                    onTap: () => Navigator.pop(context, option.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _IconTile extends StatelessWidget {
  final TierIconOption option;
  final bool selected;
  final VoidCallback onTap;
  const _IconTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.merchantTint : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.merchant : AppColors.border),
        ),
        child: Icon(option.icon, color: selected ? AppColors.merchant : AppColors.textSecondary),
      ),
    );
  }
}
