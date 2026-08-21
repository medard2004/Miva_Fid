import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_header.dart';
import '../providers/merchant_provider.dart';

class MerchantShell extends ConsumerWidget {
  const MerchantShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  Widget _buildNavItem({
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
                fontSize: 10.5,
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
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
    final int currentIndex = navigationShell.currentIndex;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final merchant = ref.watch(merchantNotifierProvider).value;
    final String location = GoRouterState.of(context).uri.path;

    final bool showHeader = !location.startsWith('/merchant/clients/') &&
        !location.startsWith('/merchant/notifications');

    final merchantName = merchant?.name ?? 'La Saveur';
    final initials = merchant?.initials ?? 'RS';
    final planLabel = merchant?.isPro ?? true ? 'Plan Pro' : 'Plan Standard';
    final smsRemaining = merchant?.smsRemaining ?? 87;

    return Scaffold(
      appBar: showHeader
          ? PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFF3F4F6),
                          child: Text(
                            initials,
                            style: AppTextStyles.monoLg().copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                          onTap: () => context.push('/merchant/notifications'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 66 + bottomPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
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
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: LucideIcons.chartColumnBig,
                      label: 'Stats',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildCenterNavItem(
                      index: 2,
                      icon: LucideIcons.qrCode,
                      label: 'Valider',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: LucideIcons.messageSquare,
                      label: 'SMS',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: LucideIcons.settings,
                      label: 'Réglages',
                      currentIndex: currentIndex,
                      context: context,
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
