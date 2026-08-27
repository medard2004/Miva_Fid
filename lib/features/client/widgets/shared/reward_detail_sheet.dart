import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:miva_fid/core/constants/reward_qr.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/models/reward.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Bottom sheet unique pour le détail d'une récompense — QR de rachat,
/// expiration, ou statut utilisée/expirée. Réutilisée depuis le détail de
/// carte et depuis l'écran Récompenses (navbar) pour garder un seul rendu,
/// et le QR est dimensionné selon la largeur d'écran (voir `_TopQrPlateCard`
/// dans card_detail_screen.dart pour le même pattern) au lieu d'une taille
/// fixe qui débordait sur petits écrans.
Future<void> showRewardDetailSheet(
  BuildContext context,
  WidgetRef ref,
  Reward reward,
) async {
  final t = AppLocalizations.of(context)!;
  final dateFormatLocale =
      Localizations.localeOf(context).languageCode == 'fr' ? 'fr_FR' : 'en_US';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) {
      final isReady = reward.isRedeemable;
      final statusLabel = isReady
          ? t.rewardStatusReady
          : (reward.isExpired ? t.rewardStatusExpired : t.rewardStatusUsed);
      final statusTone = isReady
          ? StatusTone.success
          : (reward.isExpired ? StatusTone.error : StatusTone.neutral);
      final statusIcon = isReady
          ? LucideIcons.circleCheckBig
          : (reward.isExpired ? LucideIcons.circleX : LucideIcons.circleCheckBig);

      // Sheet padding 24*2 + cadre QR padding 16*2 = 80 de marge fixe avant
      // le QR — sur un écran étroit, un QR figé déborderait sinon. Plafond
      // abaissé à 176 (au lieu de 220) pour que tout le sheet tienne sans
      // scroll sur un écran de téléphone standard.
      final qrSize = (MediaQuery.sizeOf(sheetContext).width - 80).clamp(0.0, 176.0);

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                reward.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                reward.restaurantName,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: AppColors.inkMuted()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Center(
                child: StatusBadge(
                  label: statusLabel,
                  tone: statusTone,
                  icon: statusIcon,
                ),
              ),
              const SizedBox(height: 20),
              if (isReady) ...[
                if (reward.expiresAt != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RewardCountdown(expiresAt: reward.expiresAt!, t: t),
                    ),
                  ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: '$rewardQrPrefix${reward.redeemToken}',
                          size: qrSize,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.inkSolid,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.inkSolid,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                reward.redeemToken.replaceAll('-', ' - '),
                                style: AppTextStyles.monoMedium(color: AppColors.inkSolid)
                                    .copyWith(fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: reward.redeemToken));
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text(t.cardDetailIdCopied)),
                                  );
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  LucideIcons.copy,
                                  size: 15,
                                  color: AppColors.inkSolid.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.rewardQrInstructions2,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(color: AppColors.inkMuted()),
                ),
              ] else if (reward.usedAt != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.calendarCheck, size: 22, color: AppColors.inkMuted()),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: '${t.rewardUsedDate} · ',
                            style: AppTextStyles.label(color: AppColors.inkMuted()),
                            children: [
                              TextSpan(
                                text: reward.formattedUsedDate(dateFormatLocale),
                                style: AppTextStyles.titleMedium(color: AppColors.ink),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              ] else if (reward.isExpired) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.calendarX, size: 22, color: AppColors.error),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          t.rewardStatusExpired,
                          style: AppTextStyles.titleMedium(color: AppColors.error),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              ],
              if (reward.expiresAt != null && isReady) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: reward.isExpiringSoon ? AppColors.errorTint : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: reward.isExpiringSoon
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendarClock,
                        size: 16,
                        color: reward.isExpiringSoon ? AppColors.error : AppColors.inkMuted(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.rewardExpirationDate,
                          style: AppTextStyles.label(
                              color: reward.isExpiringSoon
                                  ? AppColors.error
                                  : AppColors.inkMuted()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy', dateFormatLocale)
                            .format(reward.expiresAt!),
                        style: AppTextStyles.monoMedium(
                          color: reward.isExpiringSoon ? AppColors.error : AppColors.ink,
                        ).copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
  // Le marchand peut valider la récompense pendant que le QR est affiché :
  // on recharge à la fermeture pour refléter l'état à jour dans les deux
  // écrans d'origine (carte et navbar).
  await ref.read(rewardsProvider.notifier).loadMine();
}

class _RewardCountdown extends StatefulWidget {
  final DateTime expiresAt;
  final AppLocalizations t;

  const _RewardCountdown({required this.expiresAt, required this.t});

  @override
  State<_RewardCountdown> createState() => _RewardCountdownState();
}

class _RewardCountdownState extends State<_RewardCountdown> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTimeLeft();
        });
      }
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    _timeLeft = widget.expiresAt.difference(now);
    if (_timeLeft.isNegative) {
      _timeLeft = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) return const SizedBox.shrink();

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');

    final isExpiringSoon = _timeLeft.inHours < 48;

    final timeString = days > 0
        ? '$days ${widget.t.commonCountdownPrefix.replaceAll('-', '')} $hours:$minutes:$seconds'
        : '$hours:$minutes:$seconds';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isExpiringSoon ? AppColors.errorTint : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isExpiringSoon ? AppColors.error.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendarClock,
              size: 16, color: isExpiringSoon ? AppColors.error : AppColors.inkMuted()),
          const SizedBox(width: 8),
          Text(
            timeString,
            style: AppTextStyles.monoMedium(color: isExpiringSoon ? AppColors.error : AppColors.ink)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
