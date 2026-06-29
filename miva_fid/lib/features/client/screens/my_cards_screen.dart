import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/loyalty_cards_provider.dart';
import '../widgets/loyalty_card_widget.dart';

class MyCardsScreen extends ConsumerWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(loyaltyCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, 0),
              child: Text('Mes Cartes', style: AppTextStyles.h1()),
            ),
            const SizedBox(height: Sp.sm),
            Expanded(
              child: cardsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(Sp.md),
                  itemCount: 3,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: Sp.md),
                    child: SkeletonLoader(height: 196),
                  ),
                ),
                error: (_, __) => const EmptyState(message: 'Erreur de chargement'),
                data: (cards) => cards.isEmpty
                    ? EmptyState(
                        message: 'Aucune carte fidélité',
                        subtitle: 'Scannez le QR code d\'un commerçant pour commencer',
                        icon: Icons.credit_card_outlined,
                        action: AppButton.primary('Scanner',
                            icon: Icons.qr_code_scanner_rounded,
                            onPressed: () => context.go('/client/scanner')),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(Sp.md),
                        itemCount: cards.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: Sp.md),
                          child: GestureDetector(
                            onTap: () => ctx.go('/client/cards/${cards[i].id}'),
                            child: LoyaltyCardWidget.featured(card: cards[i]),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
