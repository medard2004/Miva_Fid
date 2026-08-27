import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Écran plein écran affiché après une validation réussie (tampon, points ou
/// montant d'achat) — reste 9 secondes, ou jusqu'à ce que le marchand tape
/// "Étape suivante", puis revient à l'écran de scan.
class ValidationSuccessOverlay extends StatefulWidget {
  const ValidationSuccessOverlay({
    super.key,
    required this.clientName,
    required this.mechanic,
    required this.stampCount,
    required this.goal,
    required this.pointsEarned,
    required this.rewardUnlocked,
    this.cashbackEarned,
  });

  final String clientName;

  /// `stamps`, `spend` ou `cashback`.
  final String mechanic;
  final int stampCount;
  final int goal;
  final int pointsEarned;
  final bool rewardUnlocked;
  final double? cashbackEarned;

  @override
  State<ValidationSuccessOverlay> createState() => _ValidationSuccessOverlayState();
}

class _ValidationSuccessOverlayState extends State<ValidationSuccessOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 9), _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  String _title(AppLocalizations t) {
    if (widget.rewardUnlocked) return t.merchantValidateRewardUnlockedTitle;
    if (widget.mechanic == 'cashback') {
      return t.merchantValidateCashbackCreditedTitle(
          (widget.cashbackEarned ?? 0).round().toString(), widget.clientName);
    }
    if (widget.mechanic == 'stamps') return t.merchantValidateStampGrantedTitle(widget.clientName);
    return t.merchantValidatePointsGrantedTitle(widget.pointsEarned.toString(), widget.clientName);
  }

  String _subtitle(AppLocalizations t) {
    if (widget.rewardUnlocked) {
      return t.merchantValidateRewardUnlockedSubtitle;
    }
    if (widget.mechanic == 'cashback') {
      return t.merchantValidateCashbackCreditedSubtitle;
    }
    if (widget.mechanic == 'stamps') {
      return t.merchantValidateStampProgressSubtitle(widget.stampCount.toString(), widget.goal.toString());
    }
    return t.merchantValidatePointsProgressSubtitle(widget.stampCount.toString(), widget.goal.toString());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.merchant,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            widget.rewardUnlocked ? LucideIcons.gift : LucideIcons.check,
                            color: AppColors.merchant,
                            size: 50,
                          ),
                        )
                            .animate()
                            .scale(
                                begin: const Offset(0, 0),
                                end: const Offset(1.1, 1.1),
                                curve: Curves.elasticOut,
                                duration: 600.ms)
                            .then()
                            .scale(end: const Offset(1.0, 1.0), duration: 150.ms),
                        const SizedBox(height: Sp.lg),
                        Text(
                          _title(t),
                          style: AppTextStyles.h2().copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Sp.xs),
                        Text(
                          _subtitle(t),
                          style: AppTextStyles.bodyMd().copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                AppButton.custom(
                  t.merchantValidateNextStepButton,
                  onPressed: _close,
                  backgroundColor: Colors.white,
                  textColor: AppColors.merchant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
