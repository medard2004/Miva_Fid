import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          final merchantName = merchant?.name ?? 'Votre Commerce';

          return statsAsync.when(
            loading: () => const _DashboardLoadingSkeleton(),
            error: (err, _) => Center(
              child: Text('Erreur stats: $err', style: AppTextStyles.bodyMd()),
            ),
              data: (stats) {
                // Determine activities list, fallback to mockup items if none exist
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

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(merchantNotifierProvider);
                    ref.invalidate(dashboardStatsProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Greeting Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, $merchantName ☀️',
                              style: AppTextStyles.h1().copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Votre activité de juin 2026',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 350.ms, delay: 100.ms).slideY(begin: 0.08, end: 0),
                        const SizedBox(height: Sp.lg),

                        // 3. Primary Actions Grid
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => context.go('/merchant/validate'),
                                borderRadius: Rd.card,
                                child: Container(
                                  height: 68,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.merchant,
                                    borderRadius: Rd.card,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.merchant.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Valider\nun tampon',
                                          style: AppTextStyles.labelBold().copyWith(
                                            color: Colors.white,
                                            height: 1.1,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.06, end: 0),
                            const SizedBox(width: Sp.sm),
                            Expanded(
                              child: InkWell(
                                onTap: () => context.go('/merchant/clients'),
                                borderRadius: Rd.card,
                                child: Container(
                                  height: 68,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: const BoxDecoration(
                                    color: AppColors.merchantTint,
                                    borderRadius: Rd.card,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.merchant.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.person_add_alt_1_rounded,
                                          color: AppColors.merchant,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Ajouter\nun client',
                                          style: AppTextStyles.labelBold().copyWith(
                                            color: AppColors.merchant,
                                            height: 1.1,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 280.ms).slideX(begin: 0.06, end: 0),
                          ],
                        ),
                        const SizedBox(height: Sp.lg),

                        // 4. KPI Row (Three columns)
                        Row(
                          children: [
                            Expanded(
                              child: _KpiCard(
                                icon: Icons.people_outline_rounded,
                                value: stats.totalClients == 0 ? '47' : stats.totalClients.toString(),
                                label: 'Clients',
                                trend: '+12',
                                trendColor: AppColors.success,
                              ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideY(begin: 0.1, end: 0),
                            ),
                            const SizedBox(width: Sp.sm),
                            Expanded(
                              child: _KpiCard(
                                icon: Icons.check_circle_outline_rounded,
                                value: stats.stampsToday == 0 ? '183' : stats.stampsToday.toString(),
                                label: 'Tampons',
                                subtext: 'ce mois',
                              ).animate().fadeIn(duration: 400.ms, delay: 420.ms).slideY(begin: 0.1, end: 0),
                            ),
                            const SizedBox(width: Sp.sm),
                            Expanded(
                              child: _KpiCard(
                                icon: Icons.card_giftcard_rounded,
                                value: stats.activeRewards == 0 ? '9' : stats.activeRewards.toString(),
                                label: 'Récomp.',
                                subtext: 'utilisées',
                              ).animate().fadeIn(duration: 400.ms, delay: 490.ms).slideY(begin: 0.1, end: 0),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.lg),

                        // 5. Monthly Activity Chart
                        const _ActivityChartCard().animate().fadeIn(duration: 500.ms, delay: 550.ms).slideY(begin: 0.06, end: 0),
                        const SizedBox(height: Sp.lg),

                        // 6. Recent Activity Section
                        _SectionCard(
                          title: 'Dernières validations',
                          actionLabel: 'Voir tout',
                          onAction: () => context.go('/merchant/clients'),
                          child: Column(
                            children: displayActivity
                                .take(3)
                                .toList()
                                .asMap()
                                .entries
                                .map((e) => ActivityRow(item: e.value)
                                    .animate()
                                    .fadeIn(duration: 350.ms, delay: Duration(milliseconds: 620 + e.key * 60))
                                    .slideX(begin: 0.04, end: 0))
                                .toList(),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                        const SizedBox(height: Sp.lg),

                        // 7. Relance Auto Section Card
                        const _RelanceAutoCard().animate().fadeIn(duration: 400.ms, delay: 750.ms).slideY(begin: 0.06, end: 0),
                        const SizedBox(height: Sp.xl),
                      ],
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

// KPI Card widget layout
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    this.subtext,
    this.trend,
    this.trendColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? subtext;
  final String? trend;
  final Color? trendColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon & optional trend badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  size: 16,
                ),
              ),
              if (trend != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: trendColor ?? AppColors.success,
                      size: 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend!,
                      style: AppTextStyles.caption().copyWith(
                        color: trendColor ?? AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          // KPI value
          Text(
            value,
            style: AppTextStyles.h1().copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          // Label
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Optional subtext
          if (subtext != null)
            Text(
              subtext!,
              style: AppTextStyles.caption().copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

// Activity Chart Widget representing the Monthly activity from mockup
class _ActivityChartCard extends StatelessWidget {
  const _ActivityChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité du mois',
            style: AppTextStyles.labelBold().copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          Text(
            'Validations par semaine',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Chart Graphic
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis markers
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['60', '45', '30', '15', '0']
                      .map((val) => Text(
                            val,
                            style: AppTextStyles.caption().copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary.withOpacity(0.6),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(width: 8),
                // Chart Bars Area
                Expanded(
                  child: Stack(
                    children: [
                      // Horizontal grid dashed lines (only over the plot height of 100)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (_) => Container(
                              height: 1,
                              color: AppColors.border.withOpacity(0.35),
                            ),
                          ),
                        ),
                      ),
                      // Bars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar('Sem 1', 38),
                          _buildBar('Sem 2', 47),
                          _buildBar('Sem 3', 54),
                          _buildBar('Sem 4', 43),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String weekLabel, int val) {
    // scale max value 60 to height of 92px
    final double barHeight = (val / 60) * 92;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: barHeight,
          decoration: const BoxDecoration(
            color: AppColors.merchant,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          weekLabel,
          style: AppTextStyles.caption().copyWith(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Container card for sections
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTextStyles.labelBold().copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.merchant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Sp.sm),
          child,
        ],
      ),
    );
  }
}

// Relance Auto Card at the bottom of page
class _RelanceAutoCard extends StatelessWidget {
  const _RelanceAutoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ClipRRect(
        borderRadius: Rd.card,
        child: Stack(
          children: [
            // Left thick line border accent
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: AppColors.merchant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RELANCE AUTO',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.sm),
                  Text(
                    '3 clients n\'ont pas visité depuis 14 jours',
                    style: AppTextStyles.bodyMd().copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.merchant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      'Voir les inactifs',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.merchant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full page skeleton loading layout
class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.circular(20)),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 120, height: 16),
                    SizedBox(height: 6),
                    SkeletonLoader(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.xl),
          const SkeletonLoader(width: 200, height: 28),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 140, height: 16),
          const SizedBox(height: Sp.xl),
          const Row(
            children: [
              Expanded(child: SkeletonLoader(height: 68)),
              SizedBox(width: Sp.md),
              Expanded(child: SkeletonLoader(height: 68)),
            ],
          ),
          const SizedBox(height: Sp.xl),
          const Row(
            children: [
              Expanded(child: SkeletonLoader(height: 100)),
              SizedBox(width: Sp.md),
              Expanded(child: SkeletonLoader(height: 100)),
              SizedBox(width: Sp.md),
              Expanded(child: SkeletonLoader(height: 100)),
            ],
          ),
          const SizedBox(height: Sp.xl),
          const SkeletonLoader(width: double.infinity, height: 160),
          const SizedBox(height: Sp.xl),
          const SkeletonLoader(width: double.infinity, height: 200),
        ],
      ),
    );
  }
}
