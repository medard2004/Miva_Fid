import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/loyalty_level.dart';
import '../../../models/loyalty_card_model.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/dashboard_stats_provider.dart';
import '../providers/merchant_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);

    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B50EC)),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erreur : $err',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── TOP HEADER ──────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statistiques',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _monthSubtitle(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(
                                LucideIcons.bell,
                                size: 18,
                                color: Color(0xFF1E293B),
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
                  const SizedBox(height: 16),

                  // ── 3 TOP KPI STAT CARDS ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildTopKpiCard(
                          icon: LucideIcons.users,
                          value: stats.totalClients.toString(),
                          label: 'Clients',
                          delay: 50,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTopKpiCard(
                          icon: LucideIcons.circleCheck,
                          value: stats.stampsToday.toString(),
                          label: 'Tampons',
                          sublabel: 'ce mois',
                          delay: 100,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTopKpiCard(
                          icon: LucideIcons.gift,
                          value: stats.activeRewards.toString(),
                          label: 'Récomp.',
                          sublabel: 'utilisées',
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEDF0F7)),
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
                        const Text(
                          'Activité du mois',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Validations par semaine',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
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
                              const SizedBox(
                                width: 24,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('60', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    Text('45', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    Text('30', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    Text('15', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    Text('0', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
                                          color: const Color(0xFFF1F5F9),
                                        ),
                                      ),
                                    ),

                                    // Vertical Bars
                                    Positioned.fill(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildBar(heightFactor: 35 / 60, label: 'Sem 1', delay: 200),
                                          _buildBar(heightFactor: 47 / 60, label: 'Sem 2', delay: 300),
                                          _buildBar(heightFactor: 56 / 60, label: 'Sem 3', delay: 400),
                                          _buildBar(heightFactor: 44 / 60, label: 'Sem 4', delay: 500),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEDF0F7)),
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
                        const Text(
                          'Répartition VIP',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Vos clients par niveau',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
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
    );
  }

  String _monthSubtitle() {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final now = DateTime.now();
    return 'Aperçu de votre activité — ${months[now.month - 1]} ${now.year}';
  }

  List<Widget> _buildVipDistribution(List<LoyaltyCardModel> cards) {
    if (cards.isEmpty) {
      return [
        const Text(
          'Aucun client pour le moment',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ];
    }

    final counts = <LoyaltyLevel, int>{};
    for (final card in cards) {
      final level = LoyaltyLevel.fromKey(card.levelKey);
      counts[level] = (counts[level] ?? 0) + 1;
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
          tierName: entry.key.label,
          count: entry.value.toString(),
          percentage: '${(ratio * 100).round()}%',
          factor: ratio,
          barColor: entry.key.color,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FD),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (sublabel != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (badge != null) ...[
                const SizedBox(width: 4),
                Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? const Color(0xFF16A34A),
                  ),
                ),
              ],
            ],
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
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              '$count • $percentage',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
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
            color: const Color(0xFFF1F5F9),
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
