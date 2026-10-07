import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/api/storage/local_preferences.dart';
import 'package:miva_fid/core/theme/app_colors.dart';
import 'package:miva_fid/core/utils/haptics.dart';
import 'package:miva_fid/core/widgets/app_dialog.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';

/// Sélecteur de mode compact.
///
/// Permet de basculer entre l'Espace Client (Wallet) et
/// l'Espace Commerçant grâce à une pilule animée fluide avec dialogue de confirmation.
/// Ne s'affiche que si le compte commerçant est déjà configuré/authentifié.
class HeaderModeSwitcher extends ConsumerWidget {
  final bool isMerchant;
  const HeaderModeSwitcher({super.key, required this.isMerchant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMerchantAuth = ref.watch(merchantAuthProvider).isAuthenticated;
    if (!isMerchantAuth) return const SizedBox.shrink();

    // Bleu pour l'espace client, Noir pour l'espace commerçant
    final activeColor = isMerchant
        ? const Color(0xFF18181B) // Noir Commerçant
        : const Color(0xFF2563EB); // Bleu Client

    return Container(
      width: 78,
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pilule active animée
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.fastOutSlowIn,
            alignment: isMerchant ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 35,
              height: 30,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Icônes interactives
          Row(
            children: [
              // ── Espace Client (Wallet) ──
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (isMerchant) {
                      final confirmed = await AppDialog.confirm(
                        context,
                        title: 'Passer en mode Client ?',
                        message: 'Souhaitez-vous basculer vers votre espace client ?',
                        confirmLabel: 'Basculer',
                        cancelLabel: 'Annuler',
                        icon: LucideIcons.wallet,
                      );
                      if (!confirmed || !context.mounted) return;
                      await AppHaptics.light();
                      await ref.read(localPreferencesProvider).setLastRole('client');
                      if (context.mounted) context.go('/client/wallet');
                    }
                  },
                  child: Center(
                    child: Icon(
                      LucideIcons.wallet,
                      size: 16,
                      color: !isMerchant
                          ? Colors.white
                          : AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              // ── Espace Commerçant ──
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (!isMerchant) {
                      final confirmed = await AppDialog.confirm(
                        context,
                        title: 'Passer en mode Commerçant ?',
                        message: 'Souhaitez-vous basculer vers votre espace commerçant ?',
                        confirmLabel: 'Basculer',
                        cancelLabel: 'Annuler',
                        icon: LucideIcons.store,
                      );
                      if (!confirmed || !context.mounted) return;
                      await AppHaptics.light();
                      await ref.read(localPreferencesProvider).setLastRole('merchant');
                      if (context.mounted) context.push('/merchant');
                    }
                  },
                  child: Center(
                    child: Icon(
                      LucideIcons.store,
                      size: 16,
                      color: isMerchant
                          ? Colors.white
                          : AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
