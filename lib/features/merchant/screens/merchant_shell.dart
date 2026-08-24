import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_header.dart';

import '../providers/clients_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

import '../widgets/merchant_avatar.dart';

class MerchantShell extends ConsumerWidget {
  const MerchantShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;



  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required int currentIndex,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final bool isActive = currentIndex == index;
    const activeColor = AppColors.merchant;
    const inactiveColor = AppColors.gray400;

    return GestureDetector(
      onTap: () {
        navigationShell.goBranch(index, initialLocation: index == currentIndex);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem({
    required int index,
    required IconData icon,
    required String label,
    required int currentIndex,
    required BuildContext context,
  }) {
    final bool isActive = currentIndex == index;
    const activeColor = AppColors.merchant;
    const inactiveColor = AppColors.gray400;

    return GestureDetector(
      onTap: () => navigationShell.goBranch(index, initialLocation: index == currentIndex),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: activeColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ces ecrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le systeme de dependances de Flutter : observer
    // la luminosite effective est leur seul declencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    final int currentIndex = navigationShell.currentIndex;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final merchant = ref.watch(merchantNotifierProvider).value;
    final String location = GoRouterState.of(context).uri.path;

    final bool showHeader = location != '/merchant/validate' && !location.startsWith('/merchant/clients/');

    final merchantName = merchant?.name ?? 'Votre Commerce';
    final initials = merchant?.initials ?? 'RS';
    final planLabel = merchant?.isPro ?? false ? 'Plan Pro' : 'Plan Standard';
    final smsRemaining = merchant?.smsRemaining ?? 100;
    
    final hideNav = ref.watch(hideMerchantNavProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: (showHeader && !hideNav && isAdmin)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 8),
                    child: Row(
                      children: [
                        MerchantAvatar(
                          logoUrl: merchant?.logoUrl,
                          initials: initials,
                          radius: 20,
                          onTap: () => context.push('/merchant/more/account/profile'),
                        ),
                        const SizedBox(width: Sp.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                merchantName,
                                style: AppTextStyles.labelBold().copyWith(color: AppColors.textPrimary, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$planLabel • $smsRemaining SMS',
                                style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        AppHeaderAction(
                          icon: LucideIcons.bell,
                          badge: true,
                          onTap: () => context.push('/merchant/more/preferences'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: navigationShell,
      bottomNavigationBar: (hideNav || !isAdmin) ? const SizedBox.shrink() : Container(
        height: 66 + bottomPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: LucideIcons.users,
                      label: 'Clients',
                      currentIndex: currentIndex,
                      context: context,
                      ref: ref,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: LucideIcons.chartColumnBig,
                      label: 'Stats',
                      currentIndex: currentIndex,
                      context: context,
                      ref: ref,
                    ),
                    _buildCenterNavItem(
                      index: 2,
                      icon: LucideIcons.scanLine,
                      label: 'Valider',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: LucideIcons.messageCircle,
                      label: 'SMS',
                      currentIndex: currentIndex,
                      context: context,
                      ref: ref,
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: LucideIcons.settings,
                      label: 'Réglages',
                      currentIndex: currentIndex,
                      context: context,
                      ref: ref,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}

