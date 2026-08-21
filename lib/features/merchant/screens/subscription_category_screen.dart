import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../client/providers/settings_provider.dart';

class SubscriptionCategoryScreen extends ConsumerWidget {
  const SubscriptionCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Abonnement & Équipe'),
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
              _buildCommonTile(
                context,
                icon: LucideIcons.creditCard,
                label: 'Mon Abonnement',
                route: '/merchant/more/subscription/plan',
              ),
              const Divider(height: 0, indent: Sp.md),
              _buildCommonTile(
                context,
                icon: LucideIcons.users,
                label: 'Membres de l\'équipe',
                route: '/merchant/more/subscription/team',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommonTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        label,
        style: AppTextStyles.bodyMd().copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: AppColors.textSecondary,
      ),
      onTap: () => context.go(route),
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 2),
    );
  }
}
