import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/loyalty_cards_provider.dart';
import '../widgets/loyalty_card_widget.dart';
import '../../merchant/widgets/stamp_grid_widget.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(loyaltyCardDetailProvider(cardId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/client/cards'),
        ),
        title: Text('Détail carte', style: AppTextStyles.h3()),
      ),
      body: cardAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(Sp.md),
          child: Column(children: [SkeletonLoader(height: 196), SkeletonCard()]),
        ),
        error: (_, __) => const Center(child: Text('Erreur de chargement')),
        data: (card) {
          if (card == null) return Center(child: Text('Carte introuvable', style: AppTextStyles.bodyMd()));
          final merchant = card.merchant;
          final required = merchant?.stampsRequired ?? 10;
          final progress = card.progressRatio(required);
          final remaining = card.stampsRemaining(required);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoyaltyCardWidget.featured(card: card),
                const SizedBox(height: Sp.lg),
                Container(
                  padding: const EdgeInsets.all(Sp.md),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: Rd.card,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06),
                          blurRadius: 12, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Votre progression', style: AppTextStyles.h3()),
                      const SizedBox(height: Sp.md),
                      StampGridWidget(filled: card.stampsCount, total: required, stampSize: 32),
                      const SizedBox(height: Sp.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${card.stampsCount} tampons',
                              style: AppTextStyles.mono().copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          Text('Encore $remaining pour votre récompense',
                              style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: Sp.sm),
                      ClipRRect(borderRadius: Rd.pill,
                        child: LinearProgressIndicator(value: progress, color: AppColors.primary,
                            backgroundColor: AppColors.border, minHeight: 10)),
                    ],
                  ),
                ),
                if (merchant?.rewardDescription != null) ...[
                  const SizedBox(height: Sp.md),
                  Container(
                    padding: const EdgeInsets.all(Sp.md),
                    decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: Rd.card,
                        border: Border.all(color: AppColors.primaryLight, width: 1.5)),
                    child: Row(
                      children: [
                        const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
                        const SizedBox(width: Sp.sm),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Votre récompense', style: AppTextStyles.caption()
                                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            Text(merchant!.rewardDescription!, style: AppTextStyles.bodyMd()
                                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        )),
                      ],
                    ),
                  ),
                ],
                if (merchant?.showReviewButton == true && merchant?.googleReviewUrl != null) ...[
                  const SizedBox(height: Sp.md),
                  AppButton.custom('Laisser un avis',
                      backgroundColor: AppColors.warningTint,
                      textColor: AppColors.warning,
                      icon: Icons.star_border_rounded,
                      onPressed: () async {
                        final url = Uri.parse(merchant!.googleReviewUrl!);
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
