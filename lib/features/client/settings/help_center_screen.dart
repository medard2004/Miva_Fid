import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final Set<int> _expandedQuestions = {0};

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'Comment fonctionne la carte de fidélité ?',
      'a': 'Présentez simplement le QR code de votre carte lors de votre passage en caisse. Le commerçant le scanne pour ajouter vos tampons et vous permettre de cumuler des points vers vos récompenses.',
    },
    {
      'q': 'Comment débloquer et utiliser une récompense ?',
      'a': 'Lorsque vous atteignez le nombre de tampons requis, votre récompense se débloque automatiquement dans l\'onglet "Récompenses". Vous pouvez la présenter au serveur ou à la caisse pour en bénéficier immédiatement.',
    },
    {
      'q': 'Comment fonctionne le parrainage ?',
      'a': 'Rendez-vous dans l\'onglet "Parrainage", choisissez l\'établissement et partagez votre code ou QR d\'invitation avec vos proches. Dès leur premier passage en caisse, votre bonus de parrainage est automatiquement crédité.',
    },
    {
      'q': 'Mes tampons ou récompenses peuvent-ils expirer ?',
      'a': 'Chaque établissement définit les règles de validité de ses cartes. Vous pouvez consulter les conditions spécifiques et la durée de validité sur le détail de chaque carte.',
    },
    {
      'q': 'Que faire si le scan du QR code échoue ?',
      'a': 'Vérifiez la luminosité de votre écran et assurez-vous que le QR code est bien net. Si le problème persiste, le commerçant peut également rechercher votre compte via votre numéro de téléphone.',
    },
  ];

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/22890000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:support@miva-fid.com?subject=Demande%20d%27assistance%20MivaFid');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: 'Centre d\'aide',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Hero card Assistance rapide
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B50EC), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B50EC).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.helpCircle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Besoin d\'un coup de main ?',
                              style: AppTextStyles.titleMedium(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Notre équipe est disponible 6j/7 pour vous aider.',
                              style: AppTextStyles.caption().copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _launchWhatsApp,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.messageCircle,
                                  size: 17,
                                  color: Color(0xFF25D366),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'WhatsApp',
                                  style: AppTextStyles.bodySmall().copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _launchEmail,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.mail,
                                  size: 17,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Email',
                                  style: AppTextStyles.bodySmall().copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Actions rapides
            Text(
              'ASSISTANCE DIRECTE',
              style: AppTextStyles.label().copyWith(
                color: AppColors.inkMuted(opacity: 0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
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
                    _QuickActionTile(
                      icon: LucideIcons.headset,
                      iconColor: const Color(0xFF5B50EC),
                      title: 'Contacter le support',
                      subtitle: 'Formulaire de contact et numéros utiles',
                      onTap: () => context.push('/client/support/contact'),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                    _QuickActionTile(
                      icon: LucideIcons.bug,
                      iconColor: const Color(0xFFE11D48),
                      title: 'Signaler un dysfonctionnement',
                      subtitle: 'Aidez-nous à corriger un bug rencontré',
                      onTap: () => context.push('/client/support/report-bug'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Section Questions fréquentes
            Text(
              'QUESTIONS FRÉQUENTES (FAQ)',
              style: AppTextStyles.label().copyWith(
                color: AppColors.inkMuted(opacity: 0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            ...List.generate(_faqs.length, (i) {
              final faq = _faqs[i];
              final isExpanded = _expandedQuestions.contains(i);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpanded ? AppColors.primary : AppColors.border,
                    width: isExpanded ? 1.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedQuestions.remove(i);
                        } else {
                          _expandedQuestions.add(i);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faq['q']!,
                                  style: AppTextStyles.bodyMedium().copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isExpanded
                                        ? AppColors.primary
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 18,
                                color: isExpanded
                                    ? AppColors.primary
                                    : AppColors.inkMuted(opacity: 0.4),
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 10),
                            Text(
                              faq['a']!,
                              style: AppTextStyles.bodySmall(
                                color: AppColors.inkMuted(opacity: 0.75),
                              ).copyWith(height: 1.45),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.inkMuted(opacity: 0.65),
                      ),
                    ),
                  ],
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
