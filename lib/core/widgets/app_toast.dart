import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Elegant, non-intrusive feedback toasts on top of the app's [SnackBarTheme].
/// Use instead of raw `ScaffoldMessenger.showSnackBar` so every confirmation,
/// error and info message in the app looks and behaves the same way.
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) =>
      _show(context, message, icon: LucideIcons.circleCheck, iconColor: AppColors.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, icon: LucideIcons.circleX, iconColor: AppColors.danger);

  static void info(BuildContext context, String message) =>
      _show(context, message, icon: LucideIcons.info, iconColor: AppColors.primaryLight);

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color iconColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMd().copyWith(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
