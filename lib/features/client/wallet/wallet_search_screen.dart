import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_shadows.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'widgets/loyalty_card_widget.dart';

/// Recherche plein écran des cartes du Wallet — écran dédié plutôt qu'un
/// champ qui s'ouvre dans l'en-tête : clavier déjà ouvert à l'arrivée,
/// résultats filtrés en direct sous forme de liste.
class WalletSearchScreen extends ConsumerStatefulWidget {
  const WalletSearchScreen({super.key});

  @override
  ConsumerState<WalletSearchScreen> createState() => _WalletSearchScreenState();
}

class _WalletSearchScreenState extends ConsumerState<WalletSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<LoyaltyCard> _filtered(List<LoyaltyCard> cards) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return cards;

    return cards.where((card) {
      return card.restaurantName.toLowerCase().contains(query) ||
          card.restaurantCategory.toLowerCase().contains(query) ||
          card.fallbackId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final cards = ref.watch(walletProvider);
    final results = _filtered(cards);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
              child: Row(
                children: [
                  AppTapScale(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(LucideIcons.arrowLeft,
                          color: AppColors.ink, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppShadows.resting,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            LucideIcons.search,
                            size: 17,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              textInputAction: TextInputAction.search,
                              style: AppTextStyles.bodyLarge().copyWith(
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                              decoration: InputDecoration(
                                hintText: t.walletSearchHint,
                                hintStyle: AppTextStyles.bodyMedium(
                                  color: AppColors.inkMuted(opacity: 0.45),
                                ).copyWith(fontSize: 15),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            AppTapScale(
                              onTap: () {
                                _controller.clear();
                                setState(() => _query = '');
                                _focusNode.requestFocus();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(7),
                                child: Icon(
                                  LucideIcons.x,
                                  color: AppColors.inkMuted(opacity: 0.7),
                                  size: 16,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: LucideIcons.searchX,
                        title: cards.isEmpty
                            ? t.walletEmptyTitle
                            : t.walletSearchNoResultsTitle,
                        message: cards.isEmpty
                            ? t.walletEmptyMessage
                            : t.walletSearchNoResultsMessage,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final card = results[i];
                        return GestureDetector(
                          onTap: () => context.push('/client/card/${card.id}'),
                          child: LoyaltyCardWidget(card: card, height: 140),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
