import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/dashboard_stats_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/activity_row.dart';
import '../widgets/kpi_pill.dart';
import '../widgets/plan_upgrade_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: false,
            floating: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.merchant],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(Sp.md),
                    child: merchantAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (m) => Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bonjour ${m?.firstName ?? ''} 👋',
                                  style: AppTextStyles.h2().copyWith(color: Colors.white),
                                ),
                                Text(
                                  "Voici votre activité d'aujourd'hui",
                                  style: AppTextStyles.caption().copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              m?.initials ?? '?',
                              style: AppTextStyles.mono().copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: SizedBox(
                height: 72,
                child: statsAsync.when(
                  loading: () => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                    children: List.generate(
                        3, (_) => const SkeletonLoader(height: 60, width: 100)),
                  ),
                  error: (_, __) => const SizedBox(),
                  data: (s) => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                    children: s.kpiPills.map((k) => KpiPill(data: k)).toList(),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        'Valider un achat',
                        icon: Icons.check_box_outlined,
                        onPressed: () => context.go('/merchant/validate'),
                      ),
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: AppButton.outlined(
                        'Envoyer SMS',
                        color: AppColors.merchant,
                        icon: Icons.message_outlined,
                        onPressed: () => context.go('/merchant/sms'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.md),
                _SectionCard(
                  title: 'Activité récente',
                  actionLabel: 'Voir tout',
                  onAction: () => context.go('/merchant/clients'),
                  child: statsAsync.when(
                    loading: () => Column(
                      children: List.generate(4, (_) => const SkeletonListTile()),
                    ),
                    error: (_, __) =>
                        Text('Erreur de chargement', style: AppTextStyles.caption()),
                    data: (s) => s.recentActivity.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: Sp.md),
                            child: Text(
                              "Aucune activité aujourd'hui",
                              style: AppTextStyles.bodyMd()
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : Column(
                            children: s.recentActivity
                                .take(5)
                                .map((a) => ActivityRow(item: a))
                                .toList(),
                          ),
                  ),
                ),
                const SizedBox(height: Sp.md),
                merchantAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (m) => m != null && !m.isPro
                      ? const PlanUpgradeCard()
                      : const SizedBox(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

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
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.h3()),
              const Spacer(),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel!,
                      style: AppTextStyles.caption().copyWith(color: AppColors.primary)),
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
