import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _removeClient(BuildContext context, String clientName) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: t.merchantClientDetailRemoveTitle,
      message: t.merchantClientDetailRemoveMessage(clientName),
      confirmLabel: t.merchantClientDetailRemoveConfirm,
      destructive: true,
    );
    if (!confirmed) return;
    if (context.mounted) {
      ToastService.showSuccess(t.merchantClientDetailRemoveToast);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    const clientName = 'Afi Mensah';
    const clientPhone = '+228 90 12 34 56';
    const clientInitials = 'AM';
    const clientTier = 'Or';
    const currentStamps = 7;
    const totalStamps = 10;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          clientName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP PROFILE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        clientInitials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    clientName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        clientPhone,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          clientTier,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.merchantClientDetailProgress,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$currentStamps/$totalStamps',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      width: double.infinity,
                      color: AppColors.border,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: currentStamps / totalStamps),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, factor, _) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: factor,
                          child: Container(color: const Color(0xFF5B50EC)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. ACTION BUTTONS ROW
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/merchant/sms/conversation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B50EC),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(LucideIcons.messageSquare,
                          size: 16, color: Colors.white),
                      label: Text(
                        t.merchantClientDetailSendSms,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(clientPhone),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(LucideIcons.phone,
                          size: 16, color: AppColors.textPrimary),
                      label: Text(
                        t.merchantClientDetailCall,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. THREE STAT CARDS ROW
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    icon: LucideIcons.stamp,
                    value: '7',
                    label: t.merchantDashboardStampsLabel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStat(
                    icon: LucideIcons.gift,
                    value: '2',
                    label: t.merchantClientDetailRewardsLabel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStat(
                    icon: LucideIcons.calendar,
                    value: 'il y a 2h',
                    label: t.merchantClientDetailLastLabel,
                    isSmallValue: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. HISTORIQUE SECTION
            Text(
              t.merchantClientDetailHistoryTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildHistoryItem(
                    icon: LucideIcons.stamp,
                    title: t.merchantClientDetailHistoryStampValidated,
                    time: 'il y a 2h',
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _buildHistoryItem(
                    icon: LucideIcons.stamp,
                    title: t.merchantClientDetailHistoryStampValidated,
                    time: 'il y a 1 semaine',
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _buildHistoryItem(
                    icon: LucideIcons.gift,
                    title: t.merchantClientDetailHistoryRewardUsed,
                    time: 'il y a 3 semaines',
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _buildHistoryItem(
                    icon: LucideIcons.userPlus,
                    title: t.merchantClientDetailHistoryEnrolled,
                    time: 'il y a 2 mois',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. RETIRER DU PROGRAMME
            InkWell(
              onTap: () => _removeClient(context, clientName),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.dangerTint),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.merchantClientDetailRemoveButton,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    bool isSmallValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmallValue ? 13 : 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required String title,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
