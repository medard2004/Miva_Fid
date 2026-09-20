import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

/// Empêche l'exécution d'actions d'écriture en mode hors ligne.
class OfflineActionGuard extends ConsumerWidget {
  final Widget child;
  final String message;
  final bool dimWhenOffline;

  const OfflineActionGuard({
    super.key,
    required this.child,
    this.message = 'Cette action nécessite une connexion Internet.',
    this.dimWhenOffline = true,
  });

  /// Vérifie si une action peut être exécutée. Affiche un SnackBar si hors-ligne.
  /// Renvoie `true` si en ligne, `false` si hors-ligne.
  static bool checkCanPerform(
    BuildContext context,
    WidgetRef ref, {
    String message = 'Cette action nécessite une connexion Internet.',
  }) {
    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    if (!isOffline) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        checkCanPerform(context, ref, message: message);
      },
      child: AbsorbPointer(
        child: Opacity(
          opacity: dimWhenOffline ? 0.55 : 1.0,
          child: child,
        ),
      ),
    );
  }
}
