import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    const inactiveColor = Color(0xFF64748B);

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
    final int currentIndex = navigationShell.currentIndex;
    final hideNav = ref.watch(hideMerchantNavProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: navigationShell,
      bottomNavigationBar: (hideNav || !isAdmin)
          ? const SizedBox.shrink()
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEDF0F7), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: LucideIcons.users,
                      label: 'Clients',
                      currentIndex: currentIndex,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: LucideIcons.chartColumnBig,
                      label: 'Stats',
                      currentIndex: currentIndex,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: LucideIcons.qrCode,
                      label: 'Valider',
                      currentIndex: currentIndex,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: LucideIcons.messageSquare,
                      label: 'SMS',
                      currentIndex: currentIndex,
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: LucideIcons.settings,
                      label: 'Réglages',
                      currentIndex: currentIndex,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
