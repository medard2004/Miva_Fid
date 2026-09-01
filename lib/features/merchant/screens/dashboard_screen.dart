import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
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

    // Listen to tab changes to replay animations whenever this tab is selected
    ref.listen<int>(merchantTabIndexProvider, (previous, next) {
      if (next == 1 && previous != 1 && mounted) {
        setState(() {
          _animVersion++;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER (STATIC) ───────────────────────────────────────
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

            // ── SCROLLABLE BODY ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey('stats_body_$_animVersion'),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 3 TOP KPI STAT CARDS ─────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildTopKpiCard(
                            icon: LucideIcons.users,
                            value: '47',
                            label: t.merchantNavClients,
                            badge: '↑ +12',
                            badgeColor: const Color(0xFF16A34A),
                            delay: 50,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTopKpiCard(
                            icon: LucideIcons.circleCheck,
                            value: '183',
                            label: t.merchantDashboardStampsLabel,
                            sublabel: t.merchantDashboardThisMonthLabel,
                            delay: 100,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTopKpiCard(
                            icon: LucideIcons.gift,
                            value: '9',
                            label: t.merchantDashboardRewardsLabel,
                            sublabel: t.merchantDashboardUsedLabel,
                            delay: 150,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── CARD: ACTIVITÉ DU MOIS (BAR CHART) ───────────────
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
                              fontWeight: FontWeight.w700,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('60',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary)),
                                      Text('45',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary)),
                                      Text('30',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary)),
                                      Text('15',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary)),
                                      Text('0',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary)),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildBar(
                                                heightFactor: 35 / 60,
                                                label: t.merchantDashboardWeekLabel(
                                                    '1'),
                                                delay: 200),
                                            _buildBar(
                                                heightFactor: 47 / 60,
                                                label: t.merchantDashboardWeekLabel(
                                                    '2'),
                                                delay: 300),
                                            _buildBar(
                                                heightFactor: 56 / 60,
                                                label: t.merchantDashboardWeekLabel(
                                                    '3'),
                                                delay: 400),
                                            _buildBar(
                                                heightFactor: 44 / 60,
                                                label: t.merchantDashboardWeekLabel(
                                                    '4'),
                                                delay: 500),
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

                    // ── CARD: RÉPARTITION VIP (PROGRESS BARS) ─────────────
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
                              fontWeight: FontWeight.w700,
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

                          // Tier 1: Argent
                          _buildTierProgress(
                            tierName: t.merchantTierSilver,
                            count: '31',
                            percentage: '66%',
                            factor: 0.66,
                            barColor: const Color(0xFF94A3B8),
                            delay: 200,
                          ),
                          const SizedBox(height: 14),

                          // Tier 2: Or
                          _buildTierProgress(
                            tierName: t.merchantTierGold,
                            count: '12',
                            percentage: '26%',
                            factor: 0.26,
                            barColor: const Color(0xFFF59E0B),
                            delay: 350,
                          ),
                          const SizedBox(height: 14),

                          // Tier 3: Platine
                          _buildTierProgress(
                            tierName: t.merchantTierPlatinum,
                            count: '4',
                            percentage: '9%',
                            factor: 0.09,
                            barColor: const Color(0xFF7C3AED),
                            delay: 500,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay))
        .slideY(begin: 0.05, end: 0);
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
                  .fadeIn(
                      duration: 400.ms, delay: Duration(milliseconds: delay)),
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
              widthFactor: factor,
              child: Container(color: barColor).animate().scaleX(
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
