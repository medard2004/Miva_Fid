import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/cache/offline_cache_database.dart';
import '../../../core/cache/offline_cache_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_service.dart';
import '../providers/clients_provider.dart';
import '../providers/dashboard_stats_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/sms_provider.dart';

class MerchantOfflineScreen extends ConsumerStatefulWidget {
  const MerchantOfflineScreen({super.key});

  @override
  ConsumerState<MerchantOfflineScreen> createState() => _MerchantOfflineScreenState();
}

class _MerchantOfflineScreenState extends ConsumerState<MerchantOfflineScreen> {
  bool _isChecking = false;
  Map<String, DateTime> _timestamps = {};
  List<OfflineMutation> _pendingMutations = [];

  @override
  void initState() {
    super.initState();
    _loadCacheMeta();
  }

  Future<void> _loadCacheMeta() async {
    try {
      final cache = ref.read(offlineCacheServiceProvider);
      final times = await cache.getMerchantCacheTimestamps();
      final mutations = await cache.getPendingMutations();
      if (mounted) {
        setState(() {
          _timestamps = times;
          _pendingMutations = mutations;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    final isOnline =
        await ref.read(connectivityStatusProvider.notifier).checkConnectivity();
    if (mounted) {
      setState(() => _isChecking = false);
      if (isOnline) {
        ToastService.showSuccess('Connexion internet confirmée.');
        await ref.read(offlineSyncProvider.notifier).syncPending();
        _loadCacheMeta();
      } else {
        ToastService.showInfo('Toujours hors ligne. Le cache local reste actif.');
      }
    }
  }

  Future<void> _syncNow() async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      final checkOnline =
          await ref.read(connectivityStatusProvider.notifier).checkConnectivity();
      if (!checkOnline) {
        ToastService.showInfo('Connexion requise pour envoyer les opérations en attente.');
        return;
      }
    }

    await ref.read(offlineSyncProvider.notifier).syncPending();
    await _loadCacheMeta();
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(clientsNotifierProvider);
    ref.invalidate(merchantNotificationsNotifierProvider);
    ref.invalidate(smsNotifierProvider);
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'Non synchronisé';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 2) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24 && dt.day == now.day) {
      return 'Aujourd\'hui à ${DateFormatter.time(dt)}';
    }
    return '${DateFormatter.short(dt)} ${DateFormatter.time(dt)}';
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    final syncState = ref.watch(offlineSyncProvider);
    final restaurant = ref.watch(merchantAuthProvider.select((s) => s.restaurant));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mode hors connexion'),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'Actualiser le cache',
            onPressed: () {
              _loadCacheMeta();
              _checkConnection();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkConnection();
          await _loadCacheMeta();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // ── HERO STATUS CARD ──────────────────────────────────────────
            _buildStatusHero(isOffline, syncState.status),
            const SizedBox(height: 20),

            // ── ACTIONS EN ATTENTE ─────────────────────────────────────────
            _buildPendingSection(syncState),
            const SizedBox(height: 24),

            // ── DONNÉES EN CACHE ───────────────────────────────────────────
            _buildCachedDataSection(restaurant),
            const SizedBox(height: 24),

            // ── SÉCURITÉ ET GARANTIE FIDÉLITÉ ──────────────────────────────
            _buildSecurityNotice(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHero(bool isOffline, SyncStatus syncStatus) {
    final isSyncing = syncStatus == SyncStatus.syncing;
    final color = isOffline
        ? const Color(0xFFD97706)
        : (isSyncing ? const Color(0xFF2563EB) : const Color(0xFF059669));
    final bgColor = isOffline
        ? const Color(0xFFFEF3C7)
        : (isSyncing ? const Color(0xFFEFF6FF) : const Color(0xFFD1FAE5));
    final icon = isOffline
        ? LucideIcons.wifiOff
        : (isSyncing ? LucideIcons.refreshCw : LucideIcons.wifi);

    final statusTitle = isOffline
        ? 'Actuellement hors connexion'
        : (isSyncing ? 'Synchronisation en cours...' : 'Connecté à Internet');

    final statusSubtitle = isOffline
        ? 'Vos données locales sont consultables et vos validations de tampons sont enregistrées de façon sécurisée.'
        : 'Toutes vos opérations sont synchronisées en direct avec le serveur.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isSyncing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: color,
                          ),
                        )
                      : Icon(icon, color: color, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: AppTextStyles.h3().copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOffline ? 'Mode Local' : 'En direct',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            statusSubtitle,
            style: AppTextStyles.bodyMd().copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isChecking ? null : _checkConnection,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isChecking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(
                _isChecking ? 'Vérification en cours...' : 'Tester la connexion',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPendingSection(OfflineSyncState syncState) {
    final count = syncState.pendingCount;
    final isSyncing = syncState.status == SyncStatus.syncing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.layers, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Opérations en attente',
                  style: AppTextStyles.h3().copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: count > 0
                    ? const Color(0xFFD97706).withValues(alpha: 0.15)
                    : const Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count > 0 ? '$count en file' : 'À jour',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: count > 0 ? const Color(0xFFD97706) : const Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (count == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCheck,
                    size: 18,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Toutes les actions sont synchronisées',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aucune opération locale en attente d\'envoi.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingMutations.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final m = _pendingMutations[index];
                final clientName = m.payload['client_name'] as String? ?? 'Client';
                final isStamp = m.actionType == 'stamp';

                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isStamp ? LucideIcons.stamp : LucideIcons.gift,
                      size: 16,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  title: Text(
                    isStamp ? 'Attribution de tampon : $clientName' : m.actionType,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Enregistré ${_formatTimestamp(m.createdAt)}'
                    '${m.attempts > 0 ? ' • ${m.attempts} essai(s)' : ''}',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: m.status == 'failed'
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      m.status == 'failed' ? 'Échec' : 'En attente',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: m.status == 'failed'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSyncing ? null : _syncNow,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.arrowUpRight, size: 16),
              label: Text(
                isSyncing ? 'Synchronisation en cours...' : 'Synchroniser maintenant',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCachedDataSection(dynamic restaurant) {
    final items = [
      _CacheItem(
        icon: LucideIcons.store,
        title: 'Établissement & Compte',
        subtitle: restaurant?.name != null ? '${restaurant.name}' : 'Non chargé',
        timestamp: _timestamps[OfflineCacheDatabase.keyMerchantAccount],
      ),
      _CacheItem(
        icon: LucideIcons.barChart3,
        title: 'Statistiques & Activité',
        subtitle: 'Indicateurs clés du tableau de bord',
        timestamp: _timestamps[OfflineCacheDatabase.keyMerchantStats],
      ),
      _CacheItem(
        icon: LucideIcons.users,
        title: 'Clients & Cartes récentes',
        subtitle: 'Recherche par nom, numéro ou carte',
        timestamp: _timestamps[OfflineCacheDatabase.keyMerchantClients],
      ),
      _CacheItem(
        icon: LucideIcons.award,
        title: 'Programme de fidélité',
        subtitle: 'Paliers et règles de validation',
        timestamp: _timestamps[OfflineCacheDatabase.keyMerchantProgramme],
      ),
      _CacheItem(
        icon: LucideIcons.messageSquare,
        title: 'Campagnes & Historique',
        subtitle: 'Messages et ciblages récents',
        timestamp: _timestamps[OfflineCacheDatabase.keyMerchantCampaigns],
      ),
      _CacheItem(
        icon: LucideIcons.bell,
        title: 'Notifications reçues',
        subtitle: 'Alertes et messages du système',
        timestamp: _timestamps[OfflineCacheDatabase.keyMerchantNotifications],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.database, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Données locales disponibles',
              style: AppTextStyles.h3().copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Ces éléments restent accessibles même sans signal internet.',
          style: AppTextStyles.bodyMd().copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final item = items[index];
              final hasData = item.timestamp != null;

              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasData
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: 16,
                    color: hasData ? AppColors.primary : Colors.grey,
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasData ? LucideIcons.checkCircle : LucideIcons.circleDashed,
                          size: 12,
                          color: hasData ? const Color(0xFF059669) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasData ? 'En cache' : 'Absent',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasData ? const Color(0xFF059669) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(item.timestamp),
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sécurité & Anti-fraude MivaFid',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toutes les validations effectuées hors ligne sont protégées par une clé unique d\'idempotence. Elles ne sont créditées définitivement qu\'après confirmation par le serveur central, garantissant l\'intégrité de votre programme.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CacheItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? timestamp;

  const _CacheItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.timestamp,
  });
}
