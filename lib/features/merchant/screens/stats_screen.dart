import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/dashboard_stats_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/activity_row.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedPeriod = 1; // 0: 7 jours, 1: 30 jours, 2: Cette année

  @override
  Widget build(BuildContext context) {
    ref.watch(merchantNotifierProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistiques',
                        style: AppTextStyles.h1().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Performance de votre fidélité',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),

              // Period Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _PeriodTab(
                      label: '7 jours',
                      isSelected: _selectedPeriod == 0,
                      onTap: () => setState(() => _selectedPeriod = 0),
                    ),
                    _PeriodTab(
                      label: '30 jours',
                      isSelected: _selectedPeriod == 1,
                      onTap: () => setState(() => _selectedPeriod = 1),
                    ),
                    _PeriodTab(
                      label: 'Cette année',
                      isSelected: _selectedPeriod == 2,
                      onTap: () => setState(() => _selectedPeriod = 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.md),

              statsAsync.when(
                loading: () => const Column(
                  children: [
                    SkeletonLoader(height: 140, borderRadius: Rd.card),
                    SizedBox(height: Sp.md),
                    SkeletonLoader(height: 200, borderRadius: Rd.card),
                  ],
                ),
                error: (err, _) => Center(
                  child: Text('Erreur: $err', style: AppTextStyles.bodyMd()),
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
                            action: 'Récompense débloquée',
                            time: 'hier',
                            initials: 'MD',
                          ),
                        ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 4 Grid Stats Cards
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.45,
                        children: [
                          _MetricCard(
                            icon: LucideIcons.users,
                            title: '${stats.totalClients > 0 ? stats.totalClients : 47}',
                            label: 'Clients fidélisés',
                            badge: '+12%',
                            isPositive: true,
                            accentColor: AppColors.merchant,
                          ),
                          _MetricCard(
                            icon: LucideIcons.qrCode,
                            title: '${stats.stampsToday > 0 ? stats.stampsToday : 143}',
                            label: 'Tampons validés',
                            badge: '+24%',
                            isPositive: true,
                            accentColor: const Color(0xFF10B981),
                          ),
                          _MetricCard(
                            icon: LucideIcons.gift,
                            title: '${stats.activeRewards > 0 ? stats.activeRewards : 18}',
                            label: 'Récompenses',
                            badge: '100% utilisé',
                            isPositive: true,
                            accentColor: const Color(0xFFF59E0B),
                          ),
                          const _MetricCard(
                            icon: LucideIcons.trendingUp,
                            title: '82 %',
                            label: 'Taux de retour',
                            badge: '+5%',
                            isPositive: true,
                            accentColor: Color(0xFF6366F1),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sp.md),

                      // Chart Card (Activity Visualization)
                      Container(
                        padding: const EdgeInsets.all(Sp.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Activité des validations',
                                  style: AppTextStyles.labelBold().copyWith(fontSize: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.merchant.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Semaine en cours',
                                    style: AppTextStyles.caption().copyWith(
                                      color: AppColors.merchant,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Sp.lg),
                            const _WeeklyBarChart(),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sp.lg),

                      // Recent Activity
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
                        ],
                      ),
                      const SizedBox(height: Sp.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < displayActivity.length; i++) ...[
                              ActivityRow(item: displayActivity[i]),
                              if (i < displayActivity.length - 1)
                                const Divider(height: 1, color: AppColors.border),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: Sp.xl),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.label,
    required this.badge,
    required this.isPositive,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String label;
  final String badge;
  final bool isPositive;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.gray400).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h1().copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart();

  @override
  Widget build(BuildContext context) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final heights = [0.45, 0.65, 0.35, 0.85, 0.95, 1.0, 0.70];
    final counts = [9, 14, 7, 21, 24, 28, 18];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(days.length, (i) {
        final isMax = heights[i] == 1.0;
        return Column(
          children: [
            Text(
              '${counts[i]}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isMax ? FontWeight.bold : FontWeight.w500,
                color: isMax ? AppColors.merchant : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: 90 * heights[i],
              decoration: BoxDecoration(
                color: isMax ? AppColors.merchant : const Color(0xFFDDD6FE),
                borderRadius: BorderRadius.circular(8),
                gradient: isMax
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.merchant, Color(0xFF4338CA)],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isMax ? FontWeight.bold : FontWeight.w500,
                color: isMax ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}
