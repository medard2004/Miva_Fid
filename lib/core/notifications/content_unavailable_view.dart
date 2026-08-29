import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';

/// État partagé "contenu indisponible" (notification pointant vers une
/// carte/récompense qui n'existe plus/a expiré) — un seul widget réutilisé
/// partout plutôt qu'une page par cas. Jamais une page vide : toujours un
/// message clair + une action de retour.
class ContentUnavailableView extends StatelessWidget {
  const ContentUnavailableView({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert, size: 36, color: AppColors.inkMuted(opacity: 0.4)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(color: AppColors.inkMuted(opacity: 0.7)),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel, style: AppTextStyles.bodyMedium(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Même état, en dialog — pour un tap qui ne justifie pas de remplacer tout
/// l'écran (ex. récompense introuvable depuis l'écran "Mes récompenses",
/// qui reste par ailleurs valide).
Future<void> showContentUnavailableDialog(
  BuildContext context, {
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Contenu indisponible'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onAction();
          },
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}
