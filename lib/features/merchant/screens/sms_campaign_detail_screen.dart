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
      if (mounted) setState(() { _error = '$e'; _loading = false; });
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
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0,
          leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop())),
        body: Center(child: Text(_error ?? 'Campagne introuvable',
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
        child: RefreshIndicator(
          color: const Color(0xFF5B50EC),
          onRefresh: _load,
          child: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _buildHeader(c)),
              SliverToBoxAdapter(child: _buildStatsRow(c, sent.length, failed.length, pending.length)),
              SliverToBoxAdapter(child: _buildInfoSection(c)),
              SliverToBoxAdapter(child: _buildMessageCard(c)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Text('Destinataires', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
              ),
              SliverToBoxAdapter(child: _buildTabBar(sent.length, failed.length, pending.length)),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRecipientList(sent, 'sent'),
                _buildRecipientList(failed, 'failed'),
                _buildRecipientList(pending, 'pending'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CampaignModel c) {
    final isPlanned = !c.isSent;
    final statusLabel = c.isScheduled ? 'Programmée' : c.isDraft ? 'Brouillon' : 'Envoyée';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
      child: Row(children: [
        IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              c.title.isNotEmpty ? c.title : (c.message.length > 28 ? '${c.message.substring(0, 28)}...' : c.message),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(targetLabel(c.recipientType),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPlanned ? AppColors.warningTint : AppColors.successTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isPlanned
                ? (AppColors.isDark ? const Color(0xFF4A3A14) : const Color(0xFFFDE68A))
                : (AppColors.isDark ? const Color(0xFF1F4A38) : const Color(0xFFBBF7D0))),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isPlanned ? LucideIcons.clock : LucideIcons.circleCheck, size: 13,
                color: isPlanned ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
            const SizedBox(width: 4),
            Text(statusLabel, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700,
                color: isPlanned ? const Color(0xFFD97706) : const Color(0xFF16A34A))),
          ]),
        ),
        if (c.isScheduled) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(LucideIcons.pencil, color: AppColors.textPrimary, size: 20),
            tooltip: 'Modifier',
            onPressed: () => context.push('/merchant/campaigns/new', extra: c),
          ),
        ],
      ]),
    );
  }

  Widget _buildStatsRow(CampaignModel c, int sentCount, int failedCount, int pendingCount) {
    final deliveryRate = c.recipientsCount > 0
        ? ((sentCount / c.recipientsCount) * 100).round()
        : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        _kpi('${c.recipientsCount}', 'Ciblés', LucideIcons.users, const Color(0xFF5B50EC)),
        const SizedBox(width: 8),
        _kpi('$sentCount', 'Livrés', LucideIcons.circleCheck, const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        _kpi('$failedCount', 'Échecs', LucideIcons.circleX, const Color(0xFFDC2626)),
        const SizedBox(width: 8),
        _kpi('$deliveryRate%', 'Taux', LucideIcons.activity, const Color(0xFF0EA5E9)),
      ]),
    );
  }

  Widget _kpi(String value, String label, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildInfoSection(CampaignModel c) {
    final typeLabel = _typeLabel(c.type);
    final fmt = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoRow(LucideIcons.tag, 'Type', typeLabel),
          const SizedBox(height: 12),
          _infoRow(LucideIcons.calendar, 'Créée le', fmt.format(c.createdAt)),
          if (c.scheduledAt != null) ...[
            const SizedBox(height: 12),
            _infoRow(LucideIcons.clock, 'Programmée pour', fmt.format(c.scheduledAt!)),
          ],
          if (c.sentAt != null) ...[
            const SizedBox(height: 12),
            _infoRow(LucideIcons.send, 'Envoyée le', fmt.format(c.sentAt!)),
          ],
          const SizedBox(height: 12),
          _infoRow(LucideIcons.users, 'Audience', targetLabel(c.recipientType)),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 10),
      Text('$label : ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          textAlign: TextAlign.right)),
    ]);
  }

  Widget _buildMessageCard(CampaignModel c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.messageSquare, size: 15, color: const Color(0xFF5B50EC)),
            const SizedBox(width: 8),
            Text('Message envoyé', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          if (c.title.isNotEmpty) ...[
            Text(c.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
          ],
          Text(c.message, style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.45, fontWeight: FontWeight.w500)),
          if (c.imageUrl != null && c.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: c.imageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${c.message.length} caractères', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('${(c.message.length / 160).ceil().clamp(1, 99)} segment(s)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTabBar(int sentCount, int failedCount, int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: const Color(0xFF5B50EC),
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: 'Livrés ($sentCount)'),
            Tab(text: 'Échecs ($failedCount)'),
            Tab(text: 'En attente ($pendingCount)'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientList(List<Map<String, dynamic>> list, String type) {
    if (list.isEmpty) {
      final label = type == 'sent' ? 'Aucun message livré' : type == 'failed' ? 'Aucun échec' : 'Aucun en attente';
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(type == 'sent' ? LucideIcons.circleCheck : type == 'failed' ? LucideIcons.circleX : LucideIcons.clock,
              size: 32, color: AppColors.border),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _recipientTile(list[i], type),
    );
  }

  Widget _recipientTile(Map<String, dynamic> r, String type) {
    final name = (r['name'] as String?) ?? 'Client';
    final phone = (r['phone'] as String?) ?? '';
    final sentAt = r['sent_at'] != null ? DateTime.tryParse(r['sent_at'].toString())?.toLocal() : null;
    final failureReason = r['failure_reason'] as String?;

    final Color accent;
    final IconData icon;
    final String statusText;
    switch (type) {
      case 'sent':
        accent = const Color(0xFF16A34A);
        icon = LucideIcons.circleCheck;
        statusText = sentAt != null ? 'Livré à ${DateFormatter.time(sentAt)}' : 'Livré';
      case 'failed':
        accent = const Color(0xFFDC2626);
        icon = LucideIcons.circleX;
        statusText = _friendlyFailure(failureReason);
      default:
        accent = const Color(0xFFF59E0B);
        icon = LucideIcons.clock;
        statusText = 'En cours d\'envoi…';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(phone, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 4),
          Text(statusText, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: accent)),
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
    'promotion' => '🏷️ Promotion',
    'reminder' => '🔔 Rappel',
    'review' => '⭐ Avis',
    'reward' => '🎁 Récompense',
    'progress' => '📈 Progression',
    'cashback' => '💰 Cashback',
    'referral' => '🤝 Parrainage',
    'announcement' => '📢 Annonce',
    _ => '📋 $type',
  };
}
