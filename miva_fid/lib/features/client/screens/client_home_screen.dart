import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/client_provider.dart';
import '../providers/loyalty_cards_provider.dart';
import '../providers/rewards_provider.dart';
import '../widgets/loyalty_card_widget.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientNotifierProvider);
    final cardsAsync = ref.watch(loyaltyCardsProvider);
    final rewardsAsync = ref.watch(rewardsProvider);

    final totalPoints = 0;
    final merchantCount = cardsAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: false,
            floating: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(Sp.md),
                    child: clientAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (client) => Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bonjour ${client?.firstName ?? ''} !',
                                  style: AppTextStyles.h2().copyWith(color: Colors.white),
                                ),
                                Text(
                                  '$totalPoints points actifs chez $merchantCount commerçant${merchantCount > 1 ? "s" : ""}',
                                  style: AppTextStyles.caption().copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              client?.initials ?? '?',
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

          // KPI Pills
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                  children: [
                    _KpiPill(value: merchantCount.toString(), label: 'Commerçants'),
                    _KpiPill(
                      value: rewardsAsync.value
                          ?.where((r) => r.isAvailable)
                          .length
                          .toString() ?? '0',
                      label: 'Récompenses',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Featured card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: cardsAsync.when(
                loading: () => const SkeletonLoader(height: 196),
                error: (_, __) => const SizedBox(),
                data: (cards) => cards.isEmpty
                    ? EmptyState(
                        message: 'Scannez votre premier QR code',
                        subtitle: 'Commencez à cumuler des tampons chez vos commerçants favoris',
                        icon: Icons.qr_code_scanner_rounded,
                        action: AppButton.primary(
                          'Scanner',
                          icon: Icons.qr_code_scanner_rounded,
                          onPressed: () => context.go('/client/scanner'),
                        ),
                      )
                    : LoyaltyCardWidget.featured(card: cards.first),
              ),
            ),
          ),

          // Other cards horizontal scroll
          SliverToBoxAdapter(
            child: cardsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (cards) {
                if (cards.length <= 1) return const SizedBox(height: Sp.md);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                      child: Text('Autres cartes', style: AppTextStyles.h3()),
                    ),
                    const SizedBox(height: Sp.sm),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                        itemCount: cards.length - 1,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(right: Sp.sm),
                          child: LoyaltyCardWidget.compact(card: cards[i + 1]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Discover section
          SliverPadding(
            padding: const EdgeInsets.all(Sp.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Commerces partenaires', style: AppTextStyles.h3()),
                const SizedBox(height: Sp.sm),
                Container(
                  padding: const EdgeInsets.all(Sp.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: Rd.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore_outlined, color: AppColors.primary),
                      const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Text(
                          'Scannez le QR code d\'un commerçant pour rejoindre son programme.',
                          style: AppTextStyles.bodyMd().copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(right: Sp.sm),
      constraints: const BoxConstraints(minWidth: 90),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.monoLg().copyWith(color: AppColors.primary)),
          Text(label, style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
