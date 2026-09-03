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
      NavItem(LucideIcons.user, LucideIcons.user, t.navProfile),
    ];

/// Bottom tab bar — dock flottant détaché des bords avec un état actif
/// suffisamment contrasté pour rester lisible sans ajouter de texte superflu.
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
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding + 6),
      child: Material(
        color: AppColors.surfaceCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.border),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(navItems.length, (i) {
              final item = navItems[i];
              final active = i == currentIndex;
              final color = active
                  ? AppColors.primary
                  : AppColors.inkMuted(opacity: 0.45);
              return Expanded(
                child: AppTapScale(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: AppMotion.pressDuration,
                    curve: AppMotion.pressCurve,
                    height: 44,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primaryTint : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          duration: AppMotion.pressDuration,
                          curve: AppMotion.pressCurve,
                          scale: active ? 1.08 : 1.0,
                            child: Icon(active ? item.activeIcon : item.icon,
                              size: 18, color: color),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            style: AppTextStyles.bodySmall(color: color).copyWith(
                              fontSize: 9,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.w500,
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
    );
  }
}
