import 'package:flutter/material.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import '../components/section_eyebrow.dart';

/// En-tête standard des pages racines de la coquille (Wallet, Récompenses,
/// Parrainage, Profil) — référence : les en-têtes de Récompenses et
/// Profil. Seuls l'eyebrow, le titre et les actions varient d'un écran à
/// l'autre ; la structure (fond, marges, typographie, bordure de pied)
/// reste strictement identique.
class AppSectionHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final List<Widget> actions;
  final bool showDivider;

  const AppSectionHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.actions = const [],
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final header = Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  SectionEyebrow(eyebrow!),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: AppTextStyles.displayMedium().copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  actions[i],
                ],
              ],
            ),
        ],
      ),
    );

    if (!showDivider) return header;

    return Column(
      children: [
        header,
        Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
