import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/dashboard_stats_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/activity_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: merchantAsync.when(
        loading: () => const _DashboardLoadingSkeleton(),
        error: (err, _) => Center(
          child: Text('Erreur: $err', style: AppTextStyles.bodyMd()),
        ),
        data: (merchant) {
          return statsAsync.when(
            loading: () => const _DashboardLoadingSkeleton(),
            error: (err, _) => Center(
              child: Text('Erreur stats: $err', style: AppTextStyles.bodyMd()),
            ),
            data: (stats) {
              final displayActivity = stats.recentActivity.isNotEmpty
                  ? stats.recentActivity
                  : const [
                      ActivityItem(
                        clientName: 'Afi Mensah',
                        action: 'Tampon validé',
                        time: 'il y a 2h',
                        initials: 'AM',
                      ),
                      ActivityItem(
                        clientName: 'Kofi Agbeko',
                        action: 'Tampon validé',
                        time: 'il y a 3h',
                        initials: 'KA',
                      ),
                      ActivityItem(
                        clientName: 'Mawuli Dossou',
                        action: 'Récompense utilisée',
                        time: 'hier',
                        initials: 'MD',
                      ),
                    ];

              return SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(Sp.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [


                      // Carousel espace publicitaire
                      SizedBox(
                        height: 180,
                        child: PageView(
                          controller: PageController(viewportFraction: 0.95),
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: _PromoBanner(
                                title: 'Fidélisez plus,\nrécompensez mieux !',
                                subtitle: 'NOUVEAU',
                                description: 'Plus de fidélité, plus de succès.',
                                color1: Color(0xFF3B1F83),
                                color2: Color(0xFF1E0F45),
                                emoji3D: '🎁',
                                showButton: false,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: _PromoBanner(
                                title: "Promotion d'été",
                                subtitle: "JUSQU'À -20%",
                                description: "Profitez de réductions exclusives sur tous nos articles.",
                                color1: AppColors.merchant,
                                color2: AppColors.primaryDark,
                                emoji3D: '☀️',
                                showButton: false,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _PromoBanner(
                                title: 'Happy Hour',
                                subtitle: 'ÉVÉNEMENT',
                                description: "Tous les vendredis de 18h à 20h, 1 acheté = 1 offert !",
                                color1: AppColors.warningDark,
                                color2: const Color(0xFF78350F),
                                emoji3D: '🍹',
                                showButton: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sp.md),

                      // Actions section
                      Text(
                        'ACTIONS',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: Sp.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              title: 'Scanner',
                              icon: LucideIcons.scanLine,
                              color: AppColors.merchant,
                              onTap: () => context.go('/merchant/validate'),
                            ),
                          ),
                          const SizedBox(width: Sp.md),
                          Expanded(
                            child: _ActionCard(
                              title: 'Nouveau client',
                              icon: LucideIcons.userPlus,
                              color: Colors.black,
                              onTap: () => context.go('/merchant/clients'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sp.lg),

                      // Recent activity section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACTIVITÉ RÉCENTE',
                            style: AppTextStyles.caption().copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/merchant/clients'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Voir tout',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.merchant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sp.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: Rd.card,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            if (displayActivity.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(Sp.md),
                                child: Text(
                                  'Aucune activité récente',
                                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                                ),
                              )
                            else
                              ...displayActivity.take(3).map((item) {
                                final isLast = displayActivity.indexOf(item) == displayActivity.take(3).length - 1;
                                return Column(
                                  children: [
                                    ActivityRow(item: item),
                                    if (!isLast)
                                      const Divider(height: 1, color: AppColors.border),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
    );
  }
}

// Elegant action card
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.08), Colors.white],
            center: Alignment.center,
            radius: 1.2,
          ),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: Icon(LucideIcons.sparkle, color: color.withValues(alpha: 0.2), size: 12),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Icon(LucideIcons.sparkle, color: color.withValues(alpha: 0.2), size: 16),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: Sp.sm),
                Text(
                  title,
                  style: AppTextStyles.labelBold().copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color1,
    required this.color2,
    this.backgroundIcon,
    this.emoji3D,
    this.showButton = false,
  });

  final String title;
  final String subtitle;
  final String description;
  final Color color1;
  final Color color2;
  final IconData? backgroundIcon;
  final String? emoji3D;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (emoji3D != null) ...[
            const Positioned(
              right: 15,
              top: 15,
              child: Text(
                '🪙',
                style: TextStyle(fontSize: 24, shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
              ),
            ),
            const Positioned(
              right: 100,
              bottom: 20,
              child: Text(
                '✨',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const Positioned(
              right: 35,
              bottom: 10,
              child: Text(
                '🪙',
                style: TextStyle(fontSize: 18, shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
              ),
            ),
            Positioned(
              right: 10,
              top: 30,
              child: Transform.rotate(
                angle: -0.1,
                child: Text(
                  emoji3D!,
                  style: const TextStyle(
                    fontSize: 80,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          if (backgroundIcon != null && emoji3D == null)
            Positioned(
              right: -10,
              top: 0,
              child: Transform.rotate(
                angle: -0.1,
                child: Icon(
                  backgroundIcon,
                  size: 140,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                  ],
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B3AED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subtitle,
                    style: AppTextStyles.caption().copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(height: Sp.sm),
                Text(
                  title,
                  style: AppTextStyles.h3().copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.2),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: Text(
                    description,
                    style: AppTextStyles.caption().copyWith(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showButton) ...[
                  const SizedBox(height: Sp.md),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        'En profiter',
                        style: AppTextStyles.caption().copyWith(color: color1, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Simple page skeleton loading layout
class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: double.infinity, height: 120),
            const SizedBox(height: Sp.xl),
            const SkeletonLoader(width: 80, height: 16),
            const SizedBox(height: Sp.md),
            const Column(
              children: [
                SkeletonLoader(width: double.infinity, height: 80),
                SizedBox(height: Sp.md),
                SkeletonLoader(width: double.infinity, height: 80),
              ],
            ),
            const SizedBox(height: Sp.xl),
            const SkeletonLoader(width: 120, height: 16),
            const SizedBox(height: Sp.md),
            const SkeletonLoader(width: double.infinity, height: 200),
          ],
        ),
      ),
    );
  }
}
