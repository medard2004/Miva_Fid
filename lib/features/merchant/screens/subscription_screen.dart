import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.merchantMoreSubscription),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing Icon Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.merchant.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.merchant.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 42,
                      color: AppColors.merchant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main Title
                Text(
                  'Service bientôt disponible',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2().copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'La gestion des formules d\'abonnement sera prochainement accessible depuis votre espace.\n\nEn attendant, vous bénéficiez d\'un accès complet et sans restriction à toutes les fonctionnalités de Miva-Fid.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd().copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Included Features Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actuellement inclus :',
                        style: AppTextStyles.labelBold().copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureRow('Programme de fidélité complet & cartes illimitées'),
                      const SizedBox(height: 8),
                      _buildFeatureRow('Campagnes de notifications push & SMS'),
                      const SizedBox(height: 8),
                      _buildFeatureRow('Gestion d\'équipe & droits d\'accès'),
                      const SizedBox(height: 8),
                      _buildFeatureRow('Statistiques en direct & suivi client'),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Return Button
                AppButton.merchant(
                  'Retour au menu',
                  icon: LucideIcons.arrowLeft,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.successTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.check,
            size: 13,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
