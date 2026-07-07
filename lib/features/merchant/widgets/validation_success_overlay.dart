import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

class ValidationSuccessOverlay extends StatelessWidget {
  const ValidationSuccessOverlay({
    super.key,
    required this.clientName,
    required this.stampCount,
    required this.stampsRequired,
    required this.onDone,
    this.onAnother,
  });

  final String clientName;
  final int stampCount;
  final int stampsRequired;
  final VoidCallback onDone;
  final VoidCallback? onAnother;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: Rd.card20),
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.merchant]),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            )
                .animate()
                .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1.1, 1.1),
                    curve: Curves.elasticOut,
                    duration: 600.ms)
                .then()
                .scale(end: const Offset(1.0, 1.0), duration: 150.ms),
            const SizedBox(height: Sp.md),
            Text('Tampon accordé à $clientName !',
                style: AppTextStyles.h2(), textAlign: TextAlign.center),
            const SizedBox(height: Sp.xs),
            Text('$stampCount sur $stampsRequired tampons',
                style: AppTextStyles.caption()
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: Sp.lg),
            Row(
              children: [
                if (onAnother != null)
                  Expanded(child: AppButton.ghost('Valider un autre', onPressed: onAnother)),
                if (onAnother != null) const SizedBox(width: Sp.sm),
                Expanded(child: AppButton.primary('Fermer', onPressed: onDone)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
