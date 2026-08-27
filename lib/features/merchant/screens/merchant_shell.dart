import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/merchant_ui_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

class MerchantShell extends ConsumerWidget {
  const MerchantShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required int currentIndex,
  }) {
    final bool isActive = currentIndex == index;
    const activeColor = Color(0xFF5B50EC);
    final inactiveColor = AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () {
          navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final int currentIndex = navigationShell.currentIndex;
    final hideNav = ref.watch(hideMerchantNavProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: (hideNav || !isAdmin)
          ? const SizedBox.shrink()
          : Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 58,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: LucideIcons.users,
                        label: t.merchantNavClients,
                        currentIndex: currentIndex,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: LucideIcons.chartColumnBig,
                        label: t.merchantNavStats,
                        currentIndex: currentIndex,
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: LucideIcons.qrCode,
                        label: t.merchantNavValidate,
                        currentIndex: currentIndex,
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: LucideIcons.messageSquare,
                        label: t.merchantNavSms,
                        currentIndex: currentIndex,
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: LucideIcons.settings,
                        label: t.merchantNavSettings,
                        currentIndex: currentIndex,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
