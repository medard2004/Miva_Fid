import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Boîte de dialogue de confirmation moderne et raffinée (déconnexion, suppression, etc.).
/// Retourne `true` si l'utilisateur confirme, `false`/`null` sinon.
class AppDialog {
  AppDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInQuad,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              backgroundColor: AppColors.surface,
              elevation: 12,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icone élégante avec halo
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: destructive
                            ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                            : const Color(0xFF5B50EC).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon ?? (destructive ? LucideIcons.trash2 : LucideIcons.helpCircle),
                        color: destructive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF5B50EC),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Titre
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Message
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Boutons d'action modernes
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.8),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                cancelLabel,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: destructive
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF5B50EC),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                confirmLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}
