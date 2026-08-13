import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../client/providers/settings_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cet écran peint via les tokens statiques d'AppColors, invisibles pour
    // le système de dépendances de Flutter : observer la luminosité
    // effective est son seul déclencheur de rebuild sur une bascule
    // clair/sombre.
    ref.watch(appBrightnessProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plus d\'options',
              style: AppTextStyles.h1().copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Sp.md),
            _buildMenuItem(
              context: context,
              icon: LucideIcons.award,
              label: 'Programme de fidélité',
              route: '/merchant/more/programme',
            ),
            _buildMenuItem(
              context: context,
              icon: LucideIcons.qrCode,
              label: 'Mon QR Code',
              route: '/merchant/more/qrcode',
            ),
            _buildMenuItem(
              context: context,
              icon: LucideIcons.globe,
              label: 'Ma Vitrine',
              route: '/merchant/more/vitrine',
            ),
            _buildMenuItem(
              context: context,
              icon: LucideIcons.settings,
              label: 'Paramètres',
              route: '/merchant/more/settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.merchant),
        title: Text(label, style: AppTextStyles.bodyMd()),
        trailing: Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
        onTap: () => context.go(route),
      ),
    );
  }
}
