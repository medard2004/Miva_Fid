import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: 'À propos',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // App Branding & Version
            Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B50EC), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B50EC).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.sparkles,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MivaFid',
                    style: AppTextStyles.displayMedium().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Version 1.0.0 (Build 1)',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Description card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À PROPOS DE MIVAFID',
                    style: AppTextStyles.label().copyWith(
                      color: AppColors.inkMuted(opacity: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MivaFid est la plateforme tout-en-un de fidélité digitale pour les commerces locaux et leurs clients. Fini les cartes en carton perdues ou oubliées : cumulez vos tampons, débloquez des avantages exclusifs et soutenez vos commerçants préférés directement depuis votre smartphone.',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.8),
                    ).copyWith(height: 1.45),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Liens légaux
            Text(
              'INFORMATIONS LÉGALES',
              style: AppTextStyles.label().copyWith(
                color: AppColors.inkMuted(opacity: 0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _AboutLinkTile(
                      icon: LucideIcons.fileText,
                      title: 'Conditions Générales d\'Utilisation (CGU)',
                      onTap: () => context.push('/client/legal/terms'),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                    _AboutLinkTile(
                      icon: LucideIcons.shieldAlert,
                      title: 'Politique de Confidentialité (RGPD)',
                      onTap: () => context.push('/client/legal/privacy'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Copyright footer
            Center(
              child: Text(
                '© 2026 MivaFid. Tous droits réservés.\nFait avec passion à Lomé, Togo.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.inkMuted(opacity: 0.5),
                  height: 1.4,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AboutLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.inkMuted(opacity: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
