import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/api/providers/api_providers.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/tier_level_icon.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/clients_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  /// Identifiant de la carte de fidélité (`loyalty_cards.id`) — c'est lui que
  /// `GET /merchant/clients/{card}` attend, la liste le fournit directement.
  final String clientId;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  late Future<Map<String, dynamic>?> _clientFuture;
  Future<List<Map<String, dynamic>>>? _historyFuture;
  String? _historyCardId;
  StreamSubscription<Map<String, dynamic>>? _cardRealtimeSub;
  StreamSubscription<Map<String, dynamic>>? _rewardRealtimeSub;

  @override
  void initState() {
    super.initState();
    _clientFuture = ref.read(merchantDashboardServiceProvider).client(widget.clientId);
    // Synchronisation temps réel (voir `MerchantRealtimeConnection`) : une
    // transaction confirmée par le backend sur CETTE carte (tampon, cashback
    // crédité/utilisé, récompense) recharge fiche + historique sans refresh
    // manuel. Filtré sur `widget.clientId` pour les cartes (payload porte
    // `id`) ; les récompenses n'ont pas de filtre fiable (`loyalty_card_id`
    // absent pour une carte supprimée) donc rechargent systématiquement —
    // volume faible, écran mono-client.
    _cardRealtimeSub = RealtimeService.instance.onCardUpdated.listen((payload) {
      if (payload['id']?.toString() == widget.clientId) _reload();
    });
    _rewardRealtimeSub = RealtimeService.instance.onRewardUpdated.listen((payload) {
      final cardId = payload['loyalty_card_id']?.toString();
      if (cardId == null || cardId == widget.clientId) _reload();
    });
  }

  @override
  void dispose() {
    _cardRealtimeSub?.cancel();
    _rewardRealtimeSub?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _clientFuture = ref.read(merchantDashboardServiceProvider).client(widget.clientId);
      _historyFuture = null;
      _historyCardId = null;
    });
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _removeStamp(Map<String, dynamic> data) async {
    try {
      await ref
          .read(clientsNotifierProvider.notifier)
          .removeBonusStamp(data['id'].toString());
      if (!mounted) return;
      AppToast.success(context, 'Tampon retiré');
      _reload();
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  Future<void> _removeClient(String clientName) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: t.merchantClientDetailRemoveTitle,
      message: t.merchantClientDetailRemoveMessage(clientName),
      confirmLabel: t.merchantClientDetailRemoveConfirm,
      destructive: true,
    );
    if (!confirmed) return;
    if (mounted) AppToast.info(context, 'Suspension bientôt disponible');
  }

  @override
  Widget build(BuildContext context) {
    // Ces écrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le système de dépendances de Flutter : observer
    // la luminosité effective est leur seul déclencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _clientFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data;
            if (data == null) {
              return Center(
                child: Text(
                  'Client introuvable',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              );
            }

            final client = data['client'] as Map<String, dynamic>?;
            final stamps = data['stamps_current'] as int? ?? 0;
            final required = merchantAsync.value?.stampsRequired ?? 10;
            final firstName = client?['first_name'] as String? ?? '';
            final lastName = client?['last_name'] as String? ?? '';
            final clientName =
                ('$firstName $lastName').trim().isNotEmpty ? ('$firstName $lastName').trim() : (client?['name'] as String? ?? 'Client');
            final clientPhone = client?['phone'] as String? ?? '';
            final clientInitials = clientName.isNotEmpty
                ? clientName.trim().split(RegExp(r'\s+')).map((w) => w[0].toUpperCase()).take(2).join()
                : '?';
            final level = data['level'] as Map<String, dynamic>?;
            final clientTier = level?['name'] as String?;
            final clientTierPosition = level?['position'] as int?;
            final clientTierIconKey = level?['icon_key'] as String?;
            final lastActivity = data['last_activity_at'] as String?;
            final lastActivityLabel = lastActivity != null
                ? DateFormatter.relative(DateTime.tryParse(lastActivity) ?? DateTime.now())
                : '—';

            return Column(
              children: [
                // ── TOP HEADER ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          LucideIcons.chevronLeft,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              t.merchantClientDetailSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── BODY CONTENT ─────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. TOP PROFILE CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    clientInitials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                clientName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (clientPhone.isNotEmpty)
                                    Text(
                                      clientPhone,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  if (clientPhone.isNotEmpty) const SizedBox(width: 8),
                                  if (clientTier != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningTint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TierLevelIcon(
                                            position: clientTierPosition,
                                            iconKey: clientTierIconKey,
                                            size: 11,
                                            color: AppColors.warningDark,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            clientTier.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.warningDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progression',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '$stamps/$required',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 6,
                                  width: double.infinity,
                                  color: AppColors.border,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: required > 0 ? (stamps / required).clamp(0.0, 1.0) : 0.0,
                                    child: Container(color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. ACTION BUTTONS ROW
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/merchant/sms'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(LucideIcons.messageSquare,
                                      size: 16, color: Colors.white),
                                  label: const Text(
                                    'Envoyer un SMS',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => _makeCall(clientPhone),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.surface,
                                    side: BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: Icon(LucideIcons.phone,
                                      size: 16, color: AppColors.textPrimary),
                                  label: Text(
                                    'Appeler',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.sm),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: () => _removeStamp(data),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              side: BorderSide(color: AppColors.dangerTint),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(LucideIcons.circleMinus,
                                size: 16, color: AppColors.danger),
                            label: const Text(
                              'Retirer un tampon',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. THREE STAT CARDS ROW
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStat(
                                icon: LucideIcons.stamp,
                                value: '$stamps/$required',
                                label: 'Tampons',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMiniStat(
                                icon: clientTier == null ? LucideIcons.medal : null,
                                iconWidget: clientTier == null
                                    ? null
                                    : TierLevelIcon(
                                        position: clientTierPosition,
                                        iconKey: clientTierIconKey,
                                        size: 18,
                                      ),
                                value: clientTier ?? '—',
                                label: 'Niveau',
                                isSmallValue: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMiniStat(
                                icon: LucideIcons.calendar,
                                value: lastActivityLabel,
                                label: 'Dernière',
                                isSmallValue: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 4. HISTORIQUE SECTION
                        Text(
                          'Historique',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildHistory(data['id'].toString()),
                        const SizedBox(height: 16),

                        // 5. RETIRER DU PROGRAMME
                        InkWell(
                          onTap: () => _removeClient(clientName),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.dangerTint),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.trash2,
                                  size: 16,
                                  color: AppColors.danger,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Retirer du programme',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: Sp.xl),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    IconData? icon,
    Widget? iconWidget,
    required String value,
    required String label,
    bool isSmallValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          iconWidget ?? Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmallValue ? 13 : 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _historyFor(String cardId) {
    if (_historyFuture == null || _historyCardId != cardId) {
      _historyCardId = cardId;
      _historyFuture =
          ref.read(merchantDashboardServiceProvider).history(cardId);
    }
    return _historyFuture!;
  }

  Widget _buildHistory(String cardId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFor(cardId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(Sp.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(Sp.lg),
              child: Center(
                child: Text(
                  "Impossible de charger l'historique.",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            );
          }
          final entries = snap.data ?? const [];
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(Sp.lg),
              child: Center(
                child: Text(
                  'Aucune opération enregistrée pour ce client.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.border),
                _buildHistoryItem(entries[i]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> entry) {
    final type = entry['type'] as String? ?? '';
    final value = entry['value'];
    final createdAt = DateTime.tryParse(entry['created_at'] as String? ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(_historyTypeIcon(type), size: 15, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _historyTypeLabel(type, value),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    DateFormatter.relative(createdAt),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _historyTypeIcon(String type) {
    return switch (type) {
      'cashback_redeem' || 'stamp_reversal' => LucideIcons.circleMinus,
      'reward' => LucideIcons.gift,
      'signup' => LucideIcons.userPlus,
      _ => LucideIcons.stamp,
    };
  }

  String _loyaltyMode() =>
      ref.read(merchantNotifierProvider).value?.loyaltyMode ?? 'stamps';

  bool get _isPointsMode {
    final mode = _loyaltyMode();
    return mode == 'points' || mode == 'spend';
  }

  String _historyTypeLabel(String type, dynamic value) {
    final n = value is num ? value : 0;
    if (type == 'stamp') {
      if (_isPointsMode) {
        return n > 1 ? '+$n points' : '+$n point';
      }
      return n == 1 ? '+1 tampon' : '+$n tampons';
    }
    if (type == 'stamp_reversal') {
      final a = n.abs();
      if (_isPointsMode) {
        return a > 1 ? '-$a points' : '-$a point';
      }
      return a == 1 ? '-1 tampon' : '-$a tampons';
    }
    return switch (type) {
      'cashback_earn' => '+$n FCFA de cashback crédité',
      'cashback_redeem' => '-$n FCFA de cashback utilisé',
      'reward' => 'Récompense utilisée',
      'signup' => 'Inscription au programme',
      _ => type,
    };
  }
}
