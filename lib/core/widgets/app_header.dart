import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Standard screen header, used instead of hand-rolled per-screen headers.
/// Keeps title placement, back-button behaviour and action spacing identical
/// across the whole app.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.accentColor = AppColors.textPrimary,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color accentColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && (onBack != null || Navigator.of(context).canPop());

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 4),
        child: Row(
          children: [
            if (canPop)
              _HeaderIconButton(
                icon: LucideIcons.arrowLeft,
                onTap: onBack ?? () => Navigator.of(context).pop(),
              )
            else
              const SizedBox(width: Sp.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: canPop ? Sp.sm : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3().copyWith(color: accentColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            if (actions != null) ...actions! else const SizedBox(width: Sp.md),
          ],
        ),
      ),
    );
  }
}

/// Consistent tap target for header icon actions (back button, notifications...).
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap, this.badge = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: AppColors.textPrimary),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}

/// Reusable action icon button for [AppHeader.actions].
class AppHeaderAction extends StatelessWidget {
  const AppHeaderAction({super.key, required this.icon, required this.onTap, this.badge = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) => _HeaderIconButton(icon: icon, onTap: onTap, badge: badge);
}
