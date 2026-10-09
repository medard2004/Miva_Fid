import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/merchant/providers/merchant_auth_provider.dart';
import '../services/connectivity_service.dart';
import '../services/offline_sync_service.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final syncState = ref.watch(offlineSyncProvider);

    Widget banner;

    if (syncState.status == SyncStatus.syncing) {
      banner = Container(
        key: const ValueKey('syncing_banner'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          top: false,
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  syncState.pendingCount > 1
                      ? 'Synchronisation en cours (${syncState.pendingCount} actions restantes)...'
                      : 'Synchronisation des données en cours...',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (syncState.status == SyncStatus.synced) {
      banner = Container(
        key: const ValueKey('synced_banner'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
        child: const SafeArea(
          bottom: false,
          top: false,
          child: Row(
            children: [
              Icon(
                LucideIcons.checkCircle2,
                size: 15,
                color: Color(0xFF10B981),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toutes les actions ont été synchronisées',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (syncState.status == SyncStatus.error &&
        !isOffline &&
        syncState.pendingCount > 0) {
      banner = GestureDetector(
        onTap: () => ref.read(offlineSyncProvider.notifier).syncPending(),
        child: Container(
          key: const ValueKey('error_banner'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            top: false,
            child: Row(
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  size: 15,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${syncState.pendingCount} action${syncState.pendingCount > 1 ? 's' : ''} non synchronisée${syncState.pendingCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
                const Text(
                  'Réessayer',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (isOffline) {
      final isMerchant = ref.watch(merchantAuthProvider).isAuthenticated;
      final pendingCount = syncState.pendingCount;
      final label = pendingCount > 0
          ? 'Mode hors ligne • $pendingCount action${pendingCount > 1 ? 's' : ''} en attente'
          : 'Mode hors ligne — Données du cache local';

      banner = GestureDetector(
        onTap: isMerchant ? () => context.push('/merchant/offline') : null,
        child: Container(
          key: const ValueKey('offline_banner'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withValues(alpha: 0.18),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFD97706).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            top: false,
            child: Row(
              children: [
                const Icon(
                  LucideIcons.wifiOff,
                  size: 15,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                if (isMerchant) ...[
                  const Text(
                    'Détails',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    ref
                        .read(connectivityStatusProvider.notifier)
                        .checkConnectivity();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.refreshCw,
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      banner = const SizedBox.shrink(key: ValueKey('empty_banner'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: child,
        );
      },
      child: banner,
    );
  }
}
