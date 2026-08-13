import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_toast.dart';

import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

class MerchantShell extends ConsumerWidget {
  const MerchantShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  Future<void> _showMoreSheet(
    BuildContext context, {
    required String planLabel,
    required int smsRemaining,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'Menu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.25,
            children: [
              _MoreMenuCard(
                icon: LucideIcons.gift,
                label: 'Programme fidélité',
                onTap: () => _navigateFromSheet(context, '/merchant/more/programme'),
              ),
              _MoreMenuCard(
                icon: LucideIcons.scan,
                label: 'Mon QR Code',
                onTap: () => _navigateFromSheet(context, '/merchant/more/qrcode'),
              ),
              _MoreMenuCard(
                icon: LucideIcons.globe,
                label: 'Ma Vitrine',
                onTap: () => _navigateFromSheet(context, '/merchant/more/vitrine'),
              ),
              _MoreMenuCard(
                icon: LucideIcons.settings,
                label: 'Paramètres',
                onTap: () => _navigateFromSheet(context, '/merchant/more/settings'),
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          const Divider(height: 1, color: AppColors.gray100, thickness: 1.2),
          const SizedBox(height: Sp.md),

          // SMS Quota
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quota SMS', style: AppTextStyles.bodyMd().copyWith(color: AppColors.gray500)),
                  Text(
                    '$smsRemaining/100',
                    style: AppTextStyles.bodyMd().copyWith(color: AppColors.gray500, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: smsRemaining / 100.0,
                  color: AppColors.merchant,
                  backgroundColor: AppColors.gray100,
                  minHeight: 5,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.sm),

          _MoreMenuRow(
            icon: LucideIcons.messageCircle,
            label: 'Support WhatsApp',
            color: AppColors.success,
            onTap: () async {
              Navigator.pop(context);
              final url = Uri.parse('https://wa.me/22899001122');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          _MoreMenuRow(
            icon: LucideIcons.logOut,
            label: 'Se déconnecter',
            color: AppColors.gray500,
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await AppDialog.confirm(
                context,
                title: 'Se déconnecter ?',
                message: 'Vous devrez vous reconnecter pour accéder à votre espace marchand.',
                confirmLabel: 'Se déconnecter',
                destructive: true,
              );
              if (!confirmed) return;
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/role-select');
            },
          ),
        ],
      ),
    );
  }

  void _navigateFromSheet(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required int currentIndex,
    required BuildContext context,
    bool isMore = false,
    String planLabel = '',
    int smsRemaining = 100,
  }) {
    final bool isActive = currentIndex == index;
    const activeColor = AppColors.merchant;
    const inactiveColor = AppColors.gray400;

    return GestureDetector(
      onTap: () {
        if (isMore) {
          _showMoreSheet(context, planLabel: planLabel, smsRemaining: smsRemaining);
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

    return Scaffold(
      appBar: showHeader
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
                          onTap: () => AppToast.info(context, 'Notifications bientôt disponibles'),
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
                      icon: LucideIcons.layoutGrid,
                      label: 'Accueil',
                      currentIndex: currentIndex,
                      context: context,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: LucideIcons.users,
                      label: 'Clients',
                      currentIndex: currentIndex,
                      context: context,
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
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: LucideIcons.ellipsis,
                      label: 'Plus',
                      currentIndex: currentIndex,
                      context: context,
                      isMore: true,
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

class _MoreMenuCard extends StatelessWidget {
  const _MoreMenuCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray100, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.gray700, size: 15),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelBold().copyWith(color: AppColors.gray900, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuRow extends StatelessWidget {
  const _MoreMenuRow({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.labelBold().copyWith(color: color, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
