import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/loyalty_level.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/loyalty_card_model.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/dashboard_stats_provider.dart';
import '../providers/merchant_provider.dart';

import 'merchant_shell.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _animVersion = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    ref.listen<int>(merchantTabIndexProvider, (previous, next) {
      if (next == 1 && previous != 1 && mounted) {
        setState(() {
          _animVersion++;
        });
      }
    });

    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER (PERSISTENT / FIXED ON SCROLL) ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.chartColumnBig,
                      color: Color(0xFF5B50EC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.merchantDashboardTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/merchant/more/notifications'),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.bell,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: statsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF5B50EC)),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur : $err',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                data: (stats) {
                  final cards = ref.watch(clientsNotifierProvider).valueOrNull?.clients ??
                      const <LoyaltyCardModel>[];

                  return RefreshIndicator(
                    color: const Color(0xFF5B50EC),
                    onRefresh: () async {
                      ref.invalidate(merchantNotifierProvider);
                      ref.invalidate(dashboardStatsProvider);
                      ref.invalidate(clientsNotifierProvider);
                    },
                    child: SingleChildScrollView(
                      key: ValueKey('stats_body_$_animVersion'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 3 TOP KPI STAT CARDS ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildTopKpiCard(
                          icon: LucideIcons.users,
                          value: stats.totalClients.toString(),
                          label: t.merchantNavClients,
                          delay: 50,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTopKpiCard(
                          icon: LucideIcons.circleCheck,
                          value: stats.stampsToday.toString(),
                          label: t.merchantDashboardStampsLabel,
                          sublabel: t.merchantDashboardThisMonthLabel,
                          delay: 100,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTopKpiCard(
                          icon: LucideIcons.gift,
                          value: stats.activeRewards.toString(),
                          label: t.merchantDashboardRewardsLabel,
                          sublabel: t.merchantDashboardUsedLabel,
                          delay: 150,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── CARD: ACTIVITÉ DU MOIS (BAR CHART) ───────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.merchantDashboardMonthActivityTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.merchantDashboardValidationsPerWeekSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Chart with animation
                        SizedBox(
                          height: 170,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Y-Axis markers
                              SizedBox(
                                width: 24,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('60', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('45', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('30', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('15', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('0', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Bars Area
                              Expanded(
                                child: Stack(
                                  children: [
                                    // Dashed Grid Lines
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        5,
                                        (index) => Container(
                                          height: 1,
                                          color: AppColors.border,
                                        ),
                                      ),
                                    ),

                                    // Vertical Bars
                                    Positioned.fill(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildBar(heightFactor: 35 / 60, label: t.merchantDashboardWeekLabel('1'), delay: 200),
                                          _buildBar(heightFactor: 47 / 60, label: t.merchantDashboardWeekLabel('2'), delay: 300),
                                          _buildBar(heightFactor: 56 / 60, label: t.merchantDashboardWeekLabel('3'), delay: 400),
                                          _buildBar(heightFactor: 44 / 60, label: t.merchantDashboardWeekLabel('4'), delay: 500),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── CARD: RÉPARTITION VIP (PROGRESS BARS) ─────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.merchantDashboardVipDistributionTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.merchantDashboardClientsByTierSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildVipDistribution(cards),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    ),
  ],
),
),
);
  }

  List<Widget> _buildVipDistribution(List<LoyaltyCardModel> cards) {
    if (cards.isEmpty) {
      return [
        Text(
          'Aucun client pour le moment',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ];
    }

    // Groupé par nom réel du palier (`levelName`), pas par la clé canonique
    // à 5 valeurs (`LoyaltyLevel.fromKey`) : au-delà du 5ème palier, cette
    // clé retombe systématiquement sur `custom`, ce qui confondait tous les
    // paliers personnalisés (et le vrai palier "Fidèle") dans un seul bloc.
    final counts = <String, int>{};
    final colorByName = <String, Color>{};
    for (final card in cards) {
      final name = card.levelName;
      if (name == null) continue;
      counts[name] = (counts[name] ?? 0) + 1;
      colorByName[name] ??=
          LoyaltyLevel.forPosition(card.levelPosition ?? 0)?.color ??
              AppColors.textSecondary;
    }
    if (counts.isEmpty) {
      return [
        Text(
          'Aucun niveau atteint pour le moment',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ];
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTiers = entries.take(3).toList();
    final total = cards.length;

    return List.generate(topTiers.length, (i) {
      final entry = topTiers[i];
      final ratio = entry.value / total;
      return Padding(
        padding: EdgeInsets.only(bottom: i == topTiers.length - 1 ? 0 : 14),
        child: _buildTierProgress(
          tierName: entry.key,
          count: entry.value.toString(),
          percentage: '${(ratio * 100).round()}%',
          factor: ratio,
          barColor: colorByName[entry.key]!,
          delay: 200 + i * 150,
        ),
      );
    });
  }

  Widget _buildTopKpiCard({
    required IconData icon,
    required String value,
    required String label,
    String? sublabel,
    String? badge,
    Color? badgeColor,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (badge != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay)).slideY(begin: 0.05, end: 0);
  }

  Widget _buildBar({
    required double heightFactor,
    required String label,
    required int delay,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              child: Container(
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B50EC),
                  borderRadius: BorderRadius.circular(8),
                ),
              )
                  .animate()
                  .scaleY(
                    begin: 0,
                    end: 1,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.bottomCenter,
                    delay: Duration(milliseconds: delay),
                  )
                  .fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTierProgress({
    required String tierName,
    required String count,
    required String percentage,
    required double factor,
    required Color barColor,
    required int delay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tierName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$count • $percentage',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 5,
            width: double.infinity,
            color: AppColors.border,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor.clamp(0.0, 1.0),
              child: Container(color: barColor)
                  .animate()
                  .scaleX(
                    begin: 0,
                    end: 1,
                    duration: 600.ms,
                    alignment: Alignment.centerLeft,
                    curve: Curves.easeOutCubic,
                    delay: Duration(milliseconds: delay),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
