import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_motion.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import '../components/app_tap_scale.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItem(this.icon, this.activeIcon, this.label);
}

List<NavItem> _navItems(AppLocalizations t) => [
      NavItem(LucideIcons.wallet, LucideIcons.wallet, t.navWallet),
      NavItem(LucideIcons.gift, LucideIcons.gift, t.navRewards),
      NavItem(LucideIcons.users, LucideIcons.users, t.navReferral),
  NavItem(LucideIcons.settings, LucideIcons.settings, t.settingsTitle),
    ];

/// Bottom tab bar — dock flottant translucide, inspire des barres d'onglets
/// système tout en conservant les codes visuels de Miva Fid.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems(AppLocalizations.of(context)!);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = AppColors.isDark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF14171D).withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.40),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Row(
                children: List.generate(navItems.length, (i) {
                  final item = navItems[i];
                  final active = i == currentIndex;
                  final color = active
                      ? AppColors.primary
                      : AppColors.inkMuted(opacity: isDark ? 0.70 : 0.60);

                  return Expanded(
                    child: AppTapScale(
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: AppMotion.pressDuration,
                        curve: AppMotion.pressCurve,
                        height: 48,
                        decoration: BoxDecoration(
                          color: active
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : AppColors.primaryTint)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              duration: AppMotion.pressDuration,
                              curve: AppMotion.pressCurve,
                              scale: active ? 1.08 : 1.0,
                              child: Icon(
                                active ? item.activeIcon : item.icon,
                                size: 19,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.label,
                                style: AppTextStyles.bodySmall(color: color).copyWith(
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
