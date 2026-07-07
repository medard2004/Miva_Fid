import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../providers/merchant_provider.dart';

class MerchantShell extends ConsumerWidget {
  const MerchantShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _showPremiumMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        title: "Plus d'options",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gérer votre commerce, vos paramètres et votre vitrine publique.',
              style: AppTextStyles.caption().copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: Sp.md),
            _buildPremiumMenuItem(
              context: context,
              icon: Icons.workspace_premium_rounded,
              iconColor: AppColors.merchant,
              bgColor: AppColors.merchantTint.withValues(alpha: 0.15),
              title: 'Programme de fidélité',
              subtitle: 'Modifier vos tampons et récompenses',
              route: '/merchant/more/programme',
            ),
            _buildPremiumMenuItem(
              context: context,
              icon: Icons.qr_code_2_rounded,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              title: 'Mon QR Code',
              subtitle: 'Maquette comptoir, téléchargement et partage',
              route: '/merchant/more/qrcode',
            ),
            _buildPremiumMenuItem(
              context: context,
              icon: Icons.public_rounded,
              iconColor: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
              title: 'Ma Vitrine',
              subtitle: 'Éditer votre page publique Lomé/Togo',
              route: '/merchant/more/vitrine',
            ),
            _buildPremiumMenuItem(
              context: context,
              icon: Icons.settings_suggest_rounded,
              iconColor: const Color(0xFF64748B),
              bgColor: const Color(0xFFF1F5F9),
              title: 'Paramètres',
              subtitle: 'Mon compte, mot de passe, SMS restants',
              route: '/merchant/more/settings',
            ),
            const SizedBox(height: Sp.md),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelBold().copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int currentIndex,
    required BuildContext context,
    bool isMore = false,
  }) {
    final bool isActive = currentIndex == index;
    final Color activeColor = AppColors.merchant;
    final Color inactiveColor = AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        if (isMore) {
          _showPremiumMoreSheet(context);
          return;
        }
        navigationShell.goBranch(index, initialLocation: index == currentIndex);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 22,
            ),
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
    final Color activeColor = AppColors.merchant;
    final Color inactiveColor = AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        navigationShell.goBranch(index, initialLocation: index == currentIndex);
      },
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
                  BoxShadow(
                    color: activeColor.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
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
    final int currentIndex = navigationShell.currentIndex;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final merchant = ref.watch(merchantNotifierProvider).value;
    final String location = GoRouterState.of(context).uri.path;

    final bool showHeader = location != '/merchant/validate' && !location.startsWith('/merchant/clients/');

    final merchantName = merchant?.name ?? 'Votre Commerce';
    final initials = merchant?.initials ?? 'RS';
    final planLabel = merchant?.isPro ?? false ? 'Plan Pro' : 'Plan Standard';
    final smsRemaining = merchant?.smsRemaining ?? 100;

    return Scaffold(
      appBar: showHeader
          ? PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.merchant,
                          child: Text(
                            initials,
                            style: AppTextStyles.monoLg().copyWith(
                              color: Colors.white,
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
                                style: AppTextStyles.labelBold().copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$planLabel • $smsRemaining SMS',
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.textPrimary,
                                size: 24,
                              ),
                              onPressed: () {},
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
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
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
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
                      icon: Icons.grid_view_outlined,
                      activeIcon: Icons.grid_view_rounded,
                      label: 'Accueil',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.people_outline_rounded,
                      activeIcon: Icons.people_rounded,
                      label: 'Clients',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildCenterNavItem(
                      index: 2,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Valider',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'SMS',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: Icons.more_horiz_rounded,
                      activeIcon: Icons.more_horiz_rounded,
                      label: 'Plus',
                      currentIndex: currentIndex,
                      context: context,
                      isMore: true,
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



