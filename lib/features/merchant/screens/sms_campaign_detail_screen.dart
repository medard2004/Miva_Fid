import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/campaign_model.dart';
import '../../client/providers/settings_provider.dart';
import 'sms_campaign_screen.dart' show targetLabel;

class SmsCampaignDetailScreen extends ConsumerStatefulWidget {
  const SmsCampaignDetailScreen({super.key, required this.campaignId});
  final String campaignId;

  @override
  ConsumerState<SmsCampaignDetailScreen> createState() =>
      _SmsCampaignDetailScreenState();
}

class _SmsCampaignDetailScreenState
    extends ConsumerState<SmsCampaignDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  CampaignModel? _campaign;
  List<Map<String, dynamic>> _recipients = [];
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _campaignSub;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
    // Écoute les mises à jour temps réel de cette campagne — le backend
    // diffuse `CampaignUpdated` à chaque changement de statut (envoi,
    // programmation, archivage). Si l'ID correspond, on recharge les données.
    _campaignSub = RealtimeService.instance.onCampaignUpdated.listen((payload) {
      final updatedId = payload['id']?.toString();
      if (updatedId == widget.campaignId) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _campaignSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final svc = ref.read(merchantDashboardServiceProvider);
      final json = await svc.campaignDetail(widget.campaignId);
      if (!mounted) return;
      final recipients = (json['recipients'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          [];
      setState(() {
        _campaign = CampaignModel.fromJson(json);
        _recipients = recipients;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _campaign == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => context.pop())),
        body: Center(
            child: Text(_error ?? 'Campagne introuvable',
                style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    final c = _campaign!;
    final sent = _recipients.where((r) => r['status'] == 'sent').toList();
    final failed = _recipients.where((r) => r['status'] == 'failed').toList();
    final pending = _recipients.where((r) => r['status'] == 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5B50EC),
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildStatsRow(
                          c, sent.length, failed.length, pending.length),
                    ),
                    SliverToBoxAdapter(child: _buildInfoSection(c)),
                    SliverToBoxAdapter(child: _buildMessageCard(c)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          'Destinataires',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildCompactTabBar(
                          sent.length, failed.length, pending.length),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      sliver: _buildActiveRecipientSliver(
                        _tabCtrl.index == 0
                            ? (sent, 'sent')
                            : _tabCtrl.index == 1
                                ? (failed, 'failed')
                                : (pending, 'pending'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CampaignModel c) {
    final isPlanned = !c.isSent;
    final statusLabel = c.isScheduled
        ? 'Programmée'
        : c.isDraft
            ? 'Brouillon'
            : 'Envoyée';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            c.title.isNotEmpty
                ? c.title
                : (c.message.length > 28
                    ? '${c.message.substring(0, 28)}...'
                    : c.message),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPlanned ? AppColors.warningTint : AppColors.successTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isPlanned ? LucideIcons.clock : LucideIcons.circleCheck,
                size: 13,
                color: isPlanned
                    ? const Color(0xFFD97706)
                    : const Color(0xFF16A34A)),
            const SizedBox(width: 4),
            Text(statusLabel,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isPlanned
                        ? const Color(0xFFD97706)
                        : const Color(0xFF16A34A))),
          ]),
        ),
        if (c.isScheduled) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(LucideIcons.pencil,
                color: AppColors.textPrimary, size: 20),
            tooltip: 'Modifier',
            onPressed: () => context.push('/merchant/campaigns/new', extra: c),
          ),
        ],
      ]),
    );
  }

  Widget _buildStatsRow(
      CampaignModel c, int sentCount, int failedCount, int pendingCount) {
    final deliveryRate = c.recipientsCount > 0
        ? ((sentCount / c.recipientsCount) * 100).round()
        : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        _kpi('${c.recipientsCount}', 'Ciblés', const Color(0xFF5B50EC)),
        const SizedBox(width: 6),
        _kpi('$sentCount', 'Livrés', const Color(0xFF16A34A)),
        const SizedBox(width: 6),
        _kpi('$failedCount', 'Échecs', const Color(0xFFDC2626)),
        const SizedBox(width: 6),
        _kpi('$deliveryRate%', 'Taux', const Color(0xFF0EA5E9)),
      ]),
    );
  }

  Widget _kpi(String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        child: Column(children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildInfoSection(CampaignModel c) {
    final typeLabel = _typeLabel(c.type);
    final fmt = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoRow(LucideIcons.tag, 'Type', typeLabel),
          const SizedBox(height: 10),
          _infoRow(LucideIcons.calendar, 'Créée le', fmt.format(c.createdAt)),
          if (c.scheduledAt != null) ...[
            const SizedBox(height: 10),
            _infoRow(LucideIcons.clock, 'Programmée pour',
                fmt.format(c.scheduledAt!)),
          ],
          if (c.sentAt != null) ...[
            const SizedBox(height: 10),
            _infoRow(LucideIcons.send, 'Envoyée le', fmt.format(c.sentAt!)),
          ],
          const SizedBox(height: 10),
          _infoRow(LucideIcons.users, 'Audience', targetLabel(c.recipientType)),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Text('$label : ',
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
      Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.right)),
    ]);
  }

  Widget _buildMessageCard(CampaignModel c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(LucideIcons.messageSquare,
                size: 15, color: Color(0xFF5B50EC)),
            const SizedBox(width: 8),
            Text('Message envoyé',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 10),
          if (c.title.isNotEmpty) ...[
            Text(c.title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
          ],
          Text(c.message,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                  fontWeight: FontWeight.w500)),
          if (c.imageUrl != null && c.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: c.imageUrl!,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 130,
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${c.message.length} caractères',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('${(c.message.length / 160).ceil().clamp(1, 99)} segment(s)',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildCompactTabBar(int sentCount, int failedCount, int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactFilterChip(
              index: 0,
              label: 'Livrés',
              count: sentCount,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildCompactFilterChip(
              index: 1,
              label: 'Échecs',
              count: failedCount,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildCompactFilterChip(
              index: 2,
              label: 'En attente',
              count: pendingCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterChip({
    required int index,
    required String label,
    required int count,
  }) {
    final isSelected = _tabCtrl.index == index;
    return InkWell(
      onTap: () {
        _tabCtrl.animateTo(index);
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B50EC) : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B50EC) : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 3.5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 3.5, vertical: 0.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRecipientSliver(
      (List<Map<String, dynamic>>, String) data) {
    final list = data.$1;
    final type = data.$2;

    if (list.isEmpty) {
      final label = type == 'sent'
          ? 'Aucun message livré'
          : type == 'failed'
              ? 'Aucun échec'
              : 'Aucun en attente';
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type == 'sent'
                      ? LucideIcons.circleCheck
                      : type == 'failed'
                          ? LucideIcons.circleX
                          : LucideIcons.clock,
                  size: 22,
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.border.withValues(alpha: 0.4),
      ),
      itemBuilder: (_, i) => _recipientTile(list[i], type),
    );
  }

  Widget _recipientTile(Map<String, dynamic> r, String type) {
    final name = (r['name'] as String?) ?? 'Client';
    final phone = (r['phone'] as String?) ?? '';
    final sentAt = r['sent_at'] != null
        ? DateTime.tryParse(r['sent_at'].toString())?.toLocal()
        : null;
    final failureReason = r['failure_reason'] as String?;

    final Color accent;
    final IconData icon;
    final String statusText;
    switch (type) {
      case 'sent':
        accent = const Color(0xFF16A34A);
        icon = LucideIcons.circleCheck;
        statusText =
            sentAt != null ? 'Livré à ${DateFormatter.time(sentAt)}' : 'Livré';
      case 'failed':
        accent = const Color(0xFFDC2626);
        icon = LucideIcons.circleX;
        statusText = _friendlyFailure(failureReason);
      default:
        accent = const Color(0xFFF59E0B);
        icon = LucideIcons.clock;
        statusText = 'En cours…';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
              child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: accent),
          )),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(phone,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(height: 2),
          Text(statusText,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
        ]),
      ]),
    );
  }

  String _friendlyFailure(String? reason) {
    if (reason == null || reason.isEmpty) return 'Échec';
    if (reason.contains('no_device_token')) return 'Pas d\'appareil';
    if (reason.contains('fcm_send_failed')) return 'Envoi échoué';
    if (reason.contains('exception')) return 'Erreur serveur';
    return 'Échec';
  }

  String _typeLabel(String type) => switch (type) {
        'promotion' => 'Promotion / Annonce',
        'reminder' => 'Rappel d\'inactivité',
        'review' => 'Notation / Avis',
        'reward' => 'Récompense',
        'progress' => 'Progression fidélité',
        'cashback' => 'Cashback',
        'referral' => 'Parrainage',
        'announcement' => 'Annonce',
        _ => type,
      };
}
