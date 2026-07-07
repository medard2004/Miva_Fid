import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

import '../providers/merchant_provider.dart';

class MerchantShell extends ConsumerWidget {
  const MerchantShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _showPremiumMoreSheet(BuildContext context, {
    String merchantName = 'Votre Commerce',
    String initials = 'RS',
    String planLabel = 'Plan Standard',
    int smsRemaining = 100,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          left: 16,
          right: 16,
          top: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row (Menu + Close Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu',
                  style: AppTextStyles.h3().copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid (2x2)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.25,
              children: [
                _buildCard(
                  context: context,
                  icon: Icons.card_giftcard_rounded,
                  iconColor: AppColors.merchant,
                  bgColor: const Color(0xFFF5F3FF),
                  label: 'Programme fidélité',
                  route: '/merchant/more/programme',
                ),
                _buildCard(
                  context: context,
                  icon: Icons.crop_free_rounded,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  label: 'Mon QR Code',
                  route: '/merchant/more/qrcode',
                ),
                _buildCard(
                  context: context,
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  label: 'Ma Vitrine',
                  route: '/merchant/more/vitrine',
                ),
                _buildCard(
                  context: context,
                  icon: Icons.settings_outlined,
                  iconColor: const Color(0xFF64748B),
                  bgColor: const Color(0xFFF1F5F9),
                  label: 'Paramètres',
                  route: '/merchant/more/settings',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Divider
            const Divider(height: 1, color: Color(0xFFEEF2F6), thickness: 1.2),
            const SizedBox(height: 16),

            // SMS Quota
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quota SMS',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$smsRemaining/100',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: smsRemaining / 100.0,
                      color: AppColors.merchant,
                      backgroundColor: const Color(0xFFF1F5F9),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Support WhatsApp
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse("https://wa.me/22899001122");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF22C55E),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Support WhatsApp',
                      style: AppTextStyles.labelBold().copyWith(
                        color: const Color(0xFF22C55E),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Logout
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.go('/role-select');
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Se déconnecter',
                      style: AppTextStyles.labelBold().copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String route,
  }) {
    return Material(
      color: const Color(0xFFFAF9FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEEF2F6), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
        splashColor: iconColor.withValues(alpha: 0.05),
        highlightColor: iconColor.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelBold().copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    String merchantName = '',
    String initials = '',
    String planLabel = '',
    int smsRemaining = 100,
  }) {
    final bool isActive = currentIndex == index;
    final Color activeColor = AppColors.merchant;
    final Color inactiveColor = AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        if (isMore) {
          _showPremiumMoreSheet(
            context,
            merchantName: merchantName,
            initials: initials,
            planLabel: planLabel,
            smsRemaining: smsRemaining,
          );
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
                    color: activeColor.withValues(alpha: 0.35),
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
              color: AppColors.border.withValues(alpha: 0.5),
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
                      merchantName: merchantName,
                      initials: initials,
                      planLabel: planLabel,
                      smsRemaining: smsRemaining,
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



