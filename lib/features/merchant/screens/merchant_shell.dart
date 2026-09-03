import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/merchant_ui_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

final merchantTabIndexProvider = StateProvider<int>((ref) => 0);

class MerchantShell extends ConsumerWidget {
  const MerchantShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int currentIndex,
    required WidgetRef ref,
  }) {
    final bool isActive = currentIndex == index;
    const activeColor = Color(0xFF5B50EC);
    final inactiveColor = AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(merchantTabIndexProvider.notifier).state = index;
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
                isActive ? activeIcon : icon,
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
              padding: EdgeInsets.only(
                top: 4,
                bottom: MediaQuery.of(context).padding.bottom + 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: t.merchantNavClients,
                    currentIndex: currentIndex,
                    ref: ref,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.bar_chart_rounded,
                    activeIcon: Icons.insert_chart_rounded,
                    label: t.merchantNavStats,
                    currentIndex: currentIndex,
                    ref: ref,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.qr_code_scanner_rounded,
                    activeIcon: Icons.qr_code_2_rounded,
                    label: t.merchantNavValidate,
                    currentIndex: currentIndex,
                    ref: ref,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: t.merchantNavSms,
                    currentIndex: currentIndex,
                    ref: ref,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: t.merchantNavSettings,
                    currentIndex: currentIndex,
                    ref: ref,
                  ),
                ],
              ),
            ),
    );
  }
}
