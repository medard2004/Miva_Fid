import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/toast_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  /// Clé en cours de sauvegarde (désactive son switch pendant l'appel API).
  String? _saving;

  Future<void> _toggle(String key, bool value) async {
    setState(() => _saving = key);
    final t = AppLocalizations.of(context)!;
    final ok = await ref
        .read(merchantAuthProvider.notifier)
        .updateNotificationPreferences({key: value});

    if (!mounted) return;
    if (ok) {
      ToastService.showSuccess('Préférence enregistrée');
    } else {
      ToastService.showError(t.merchantNotifUpdateError);
    }
    setState(() => _saving = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final prefs =
        ref.watch(merchantAuthProvider.select((s) => s.restaurant?.notificationPreferences)) ??
            const {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.settingsPreferences),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.merchant.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.merchant.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.bellRing,
                    color: AppColors.merchant,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alertes & Notifications en direct',
                          style: AppTextStyles.labelBold().copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Activez les notifications prioritaires pour suivre l\'activité de votre établissement en temps réel.',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Functional Preferences Switches
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: Rd.card,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildNotifSwitch(
                    icon: LucideIcons.userPlus,
                    key: 'new_client',
                    title: t.merchantNotifNewClientTitle,
                    subtitle: t.merchantNotifNewClientSubtitle,
                    value: prefs['new_client'] ?? true,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildNotifSwitch(
                    icon: LucideIcons.gift,
                    key: 'reward',
                    title: t.merchantNotifRewardTitle,
                    subtitle: t.merchantNotifRewardSubtitle,
                    value: prefs['reward'] ?? true,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildNotifSwitch(
                    icon: LucideIcons.messageSquareWarning,
                    key: 'low_sms',
                    title: t.merchantNotifLowSmsTitle,
                    subtitle: t.merchantNotifLowSmsSubtitle,
                    value: prefs['low_sms'] ?? true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifSwitch({
    required IconData icon,
    required String key,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.merchant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.merchant, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd().copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _saving == key
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.merchant,
                  ),
                )
              : Switch.adaptive(
                  value: value,
                  onChanged: (val) => _toggle(key, val),
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.merchant,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.border,
                ),
        ],
      ),
    );
  }
}
