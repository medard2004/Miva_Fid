import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La synchronisation et le fonctionnement hors ligne opèrent silencieusement
/// en arrière-plan sans perturber l'expérience utilisateur.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Les mutations hors-ligne continuent de fonctionner automatiquement
    // (OfflineSyncService se synchronise dès que le réseau revient),
    // mais aucun bandeau intrusif n'est imposé à l'écran.
    return const SizedBox.shrink();
  }
}
