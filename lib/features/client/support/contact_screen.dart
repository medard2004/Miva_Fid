import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:miva_fid/core/utils/toast_service.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Écran Nous contacter — Épuré, compact et sans surcharge de cadres.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  static const String _supportPhone = '+22890123456';
  static const String _supportEmail = 'support@miva-fid.com';

  Future<void> _launchWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/22890123456?text=${Uri.encodeComponent("Bonjour Miva-Fid, j'ai besoin d'aide avec mon compte client.")}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ToastService.showError('Impossible d\'ouvrir WhatsApp');
      }
    } catch (_) {
      ToastService.showError('Impossible d\'ouvrir WhatsApp');
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Demande d\'assistance client Miva-Fid',
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ToastService.showError('Impossible d\'ouvrir l\'application email');
      }
    } catch (_) {
      ToastService.showError('Impossible d\'ouvrir l\'application email');
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ToastService.showError('Impossible de lancer l\'appel');
      }
    } catch (_) {
      ToastService.showError('Impossible de lancer l\'appel');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: t.contactTitle.toUpperCase(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête simple et aéré (sans cadre lourd)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.headset,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.contactTitle,
                            style: AppTextStyles.titleMedium().copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.contactSubtitle,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.inkMuted(opacity: 0.7),
                            ).copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SectionEyebrow(t.settingsSupport.toUpperCase()),
              const SizedBox(height: 6),

              // Liste unique compacte des canaux de contact
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _ContactOptionTile(
                      icon: LucideIcons.messageCircle,
                      iconColor: const Color(0xFF25D366),
                      iconBgColor: const Color(0xFF25D366).withValues(alpha: 0.12),
                      title: t.contactWhatsApp,
                      subtitle: t.contactWhatsAppSubtitle,
                      onTap: () => _launchWhatsApp(context),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _ContactOptionTile(
                      icon: LucideIcons.mail,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primaryTint,
                      title: t.contactEmail,
                      subtitle: t.contactEmailSubtitle,
                      onTap: () => _launchEmail(context),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _ContactOptionTile(
                      icon: LucideIcons.phoneCall,
                      iconColor: const Color(0xFF0284C7),
                      iconBgColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      title: t.contactPhone,
                      subtitle: t.contactPhoneSubtitle,
                      onTap: () => _launchPhone(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Horaires d'ouverture (ligne simple épurée)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: AppColors.inkMuted(opacity: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${t.contactHours} : ${t.contactHoursSubtitle}',
                        style: AppTextStyles.bodySmall(
                          color: AppColors.inkMuted(opacity: 0.65),
                        ).copyWith(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Accès direct Signaler un bug (compact)
              AppTapScale(
                onTap: () => context.push('/client/support/report-bug'),
                scaleDown: 0.99,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.bug,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.reportBugTitle,
                          style: AppTextStyles.bodyMedium().copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.inkMuted(opacity: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTapScale(
      onTap: onTap,
      scaleDown: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.6),
                    ).copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.inkMuted(opacity: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
