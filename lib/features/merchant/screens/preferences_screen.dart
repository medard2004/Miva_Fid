import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
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
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.merchantNotifUpdateError),
          backgroundColor: AppColors.danger,
        ),
      );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: Rd.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildNotifSwitch(
                key: 'new_client',
                title: t.merchantNotifNewClientTitle,
                subtitle: t.merchantNotifNewClientSubtitle,
                value: prefs['new_client'] ?? true,
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                key: 'reward',
                title: t.merchantNotifRewardTitle,
                subtitle: t.merchantNotifRewardSubtitle,
                value: prefs['reward'] ?? true,
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                key: 'low_sms',
                title: t.merchantNotifLowSmsTitle,
                subtitle: t.merchantNotifLowSmsSubtitle,
                value: prefs['low_sms'] ?? true,
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                key: 'weekly_report',
                title: t.merchantNotifWeeklyReportTitle,
                subtitle: t.merchantNotifWeeklyReportSubtitle,
                value: prefs['weekly_report'] ?? false,
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                key: 'promotions',
                title: t.merchantNotifPromotionsTitle,
                subtitle: t.merchantNotifPromotionsSubtitle,
                value: prefs['promotions'] ?? false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifSwitch({
    required String key,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
      title: Text(
        title,
        style: AppTextStyles.bodyMd().copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
      ),
      trailing: _saving == key
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.merchant),
            )
          : Switch(
              value: value,
              onChanged: (val) => _toggle(key, val),
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.merchant,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.border,
              trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                return Colors.transparent;
              }),
            ),
    );
  }
}
