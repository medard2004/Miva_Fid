import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/merchant_ui_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

final merchantTabIndexProvider = StateProvider<int>((ref) => 0);

class MerchantShell extends ConsumerStatefulWidget {
  const MerchantShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends ConsumerState<MerchantShell> {
  DateTime? _lastBackPressTime;

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
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 19,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                    letterSpacing: 0.1,
                    height: 1.1,
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
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final int currentIndex = widget.navigationShell.currentIndex;
    final hideNav = ref.watch(hideMerchantNavProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Si l'utilisateur n'est pas sur l'onglet principal (Valider = index 2), on y retourne d'abord
        if (currentIndex != 2) {
          ref.read(merchantTabIndexProvider.notifier).state = 2;
          widget.navigationShell.goBranch(2);
          return;
        }
        // Sur l'onglet principal : double tap requis dans les 2 secondes pour quitter
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appuyez à nouveau pour quitter l\'application'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        // Quitter l'application
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: widget.navigationShell),
            ],
          ),
        ),
        bottomNavigationBar: (hideNav || !isAdmin)
            ? const SizedBox.shrink()
            : Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.6),
                    width: 0.5,
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                top: 2,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom
                    : 4,
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
      ),
    );
  }
}
