import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Confirmation dialog for actions that are hard to undo (sign-out, delete...).
/// Returns `true` when the user confirms, `false`/`null` otherwise.
class AppDialog {
  AppDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.h3()),
        content: Text(
          message,
          style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
        actions: [
          Expanded(
            child: AppButton.ghost(
              cancelLabel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: destructive
                ? AppButton.danger(
                    confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  )
                : AppButton.primary(
                    confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
