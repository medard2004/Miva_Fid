import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../client/providers/settings_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Local state for notification switches
  bool _notifNewClient = true;
  bool _notifReward = true;
  bool _notifLowSms = true;
  bool _notifWeeklyReport = false;
  bool _notifPromotions = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Rd.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildNotifSwitch(
                title: 'Nouveau client',
                subtitle: 'Notif. à chaque inscription',
                value: _notifNewClient,
                onChanged: (val) => setState(() => _notifNewClient = val),
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                title: 'Récompense gagnée',
                subtitle: 'Quand un palier est atteint',
                value: _notifReward,
                onChanged: (val) => setState(() => _notifReward = val),
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                title: 'Quota SMS faible',
                subtitle: 'Sous 20 SMS restants',
                value: _notifLowSms,
                onChanged: (val) => setState(() => _notifLowSms = val),
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                title: 'Rapport hebdomadaire',
                subtitle: 'Tous les lundis matin',
                value: _notifWeeklyReport,
                onChanged: (val) => setState(() => _notifWeeklyReport = val),
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                title: 'Promotions Miva-Fid',
                subtitle: 'Offres et nouveautés',
                value: _notifPromotions,
                onChanged: (val) => setState(() => _notifPromotions = val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
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
