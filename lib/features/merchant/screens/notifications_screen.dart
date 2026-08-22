import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  /// Clé en cours de sauvegarde (désactive son switch pendant l'appel API).
  String? _saving;

  Future<void> _toggle(String key, bool value) async {
    setState(() => _saving = key);
    final ok = await ref
        .read(merchantAuthProvider.notifier)
        .updateNotificationPreferences({key: value});
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de mettre à jour cette préférence. Réessayez.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    setState(() => _saving = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final prefs =
        ref.watch(merchantAuthProvider.select((s) => s.restaurant?.notificationPreferences)) ??
            const {};

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
                key: 'new_client',
                title: 'Nouveau client',
                subtitle: 'Notif. à chaque inscription',
                value: prefs['new_client'] ?? true,
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                key: 'reward',
                title: 'Récompense gagnée',
                subtitle: 'Quand un palier est atteint',
                value: prefs['reward'] ?? true,
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                key: 'low_sms',
                title: 'Quota SMS faible',
                subtitle: 'Sous 20 SMS restants',
                value: prefs['low_sms'] ?? true,
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                key: 'weekly_report',
                title: 'Rapport hebdomadaire',
                subtitle: 'Tous les lundis matin',
                value: prefs['weekly_report'] ?? false,
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildNotifSwitch(
                key: 'promotions',
                title: 'Promotions Miva-Fid',
                subtitle: 'Offres et nouveautés',
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
