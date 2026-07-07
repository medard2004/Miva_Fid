import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
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
              icon: Icons.workspace_premium_outlined,
              label: 'Programme de fidélité',
              route: '/merchant/more/programme',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.qr_code_outlined,
              label: 'Mon QR Code',
              route: '/merchant/more/qrcode',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.public_outlined,
              label: 'Ma Vitrine',
              route: '/merchant/more/vitrine',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.settings_outlined,
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
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: () => context.go(route),
      ),
    );
  }
}
