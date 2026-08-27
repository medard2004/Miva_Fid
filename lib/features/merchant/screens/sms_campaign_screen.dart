import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/sms_campaign_model.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_provider.dart';
import '../providers/sms_provider.dart';

class SmsCampaignScreen extends ConsumerStatefulWidget {
  const SmsCampaignScreen({super.key});

  @override
  ConsumerState<SmsCampaignScreen> createState() => _SmsCampaignScreenState();
}

class _SmsCampaignScreenState extends ConsumerState<SmsCampaignScreen> {
  void _openNewCampaignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewCampaignSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(merchantNotifierProvider).value;
    final smsAsync = ref.watch(smsNotifierProvider);
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP HEADER ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.messageSquare,
                      color: Color(0xFF5B50EC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SMS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Campagnes & messages • ${merchant?.smsRemaining ?? 0} SMS restants',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openNewCampaignSheet(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B50EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.push('/merchant/more/notifications'),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            LucideIcons.bell,
                            size: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 3 KPI STAT CARDS ROW ─────────────────────────────────────
              _buildKpiRow(smsAsync, merchant?.smsRemaining),
              const SizedBox(height: 20),

              // ── SECTION HISTORIQUE ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historique',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    smsAsync.maybeWhen(
                      data: (list) =>
                          '${list.length} campagne${list.length > 1 ? 's' : ''}',
                      orElse: () => '',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Campaign Cards
              smsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: Color(0xFF5B50EC),
                    ),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                data: (campaigns) {
                  if (campaigns.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.messageSquare,
                              size: 32,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Aucune campagne pour le moment',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final camp in campaigns)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildCampaignCard(camp),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow(AsyncValue<List<SmsCampaignModel>> smsAsync, int? smsRemaining) {
    final campaigns = smsAsync.value ?? const <SmsCampaignModel>[];
    final sentCount = campaigns.where((c) => c.isSent).length;
    final reached = campaigns.fold<int>(0, (sum, c) => sum + c.recipientsCount);

    return Row(
      children: [
        Expanded(
          child: _buildKpiBox(value: '$sentCount', label: 'Envoyées'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiBox(value: '$reached', label: 'Atteints'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiBox(
            value: '${smsRemaining ?? 0}',
            label: 'Solde SMS',
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignCard(SmsCampaignModel camp) {
    final isPlanned = !camp.isSent;
    final status = camp.isScheduled || camp.isDraft ? 'Planifiée' : 'Envoyée';
    final date = camp.sentAt ?? camp.createdAt;
    final time = isPlanned && camp.scheduledAt != null
        ? 'Prévue ${DateFormatter.short(camp.scheduledAt!)}'
        : DateFormatter.relative(date);
    final title = camp.message.length > 24
        ? '${camp.message.substring(0, 24)}...'
        : camp.message;

    return InkWell(
      onTap: () => context.push('/merchant/sms/campaign/${camp.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDF0F7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPlanned
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPlanned
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPlanned ? LucideIcons.clock : LucideIcons.circleCheck,
                        size: 11,
                        color: isPlanned
                            ? const Color(0xFFD97706)
                            : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: isPlanned
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_targetLabel(camp.recipientType)} • $time',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${camp.recipientsCount}/${camp.recipientsCount} envoyés',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(String? recipientType) {
    switch (recipientType) {
      case 'all':
        return 'Tous les clients';
      case 'inactive':
        return 'Clients inactifs';
      case 'near_reward':
        return 'Proches récompense';
      case 'manual':
        return 'Sélection manuelle';
      default:
        return 'Tous les clients';
    }
  }

  Widget _buildKpiBox({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewCampaignSheet extends ConsumerStatefulWidget {
  const _NewCampaignSheet();

  @override
  ConsumerState<_NewCampaignSheet> createState() => _NewCampaignSheetState();
}

class _NewCampaignSheetState extends ConsumerState<_NewCampaignSheet> {
  static const _targets = [
    ('all', 'Tous les clients actifs'),
    ('inactive', 'Clients inactifs'),
    ('near_reward', 'Proches d\'une récompense'),
  ];

  final _msgCtrl = TextEditingController();
  String _target = 'all';
  bool _loading = false;
  final Map<String, int?> _counts = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    for (final (type, _) in _targets) {
      try {
        final count = await ref
            .read(smsNotifierProvider.notifier)
            .countRecipients(type);
        if (mounted) setState(() => _counts[type] = count);
      } catch (_) {
        if (mounted) setState(() => _counts[type] = null);
      }
    }
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      ToastService.showError('Veuillez saisir un message');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Envoyer la campagne SMS ?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Ce message sera envoyé à vos clients.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Envoyer',
              style: TextStyle(
                color: Color(0xFF5B50EC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(smsNotifierProvider.notifier).sendCampaign(
            message: msg,
            recipientType: _target,
          );
      if (mounted) {
        Navigator.pop(context);
        ToastService.showSuccess('Campagne SMS envoyée avec succès !');
      }
    } catch (e) {
      if (mounted) ToastService.showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nouvelle Campagne SMS',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Destinataires',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _target,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            items: _targets.map((t) {
              final count = _counts[t.$1];
              final suffix = count == null ? '' : ' ($count)';
              return DropdownMenuItem(
                value: t.$1,
                child: Text('${t.$2}$suffix', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) => setState(() => _target = v ?? 'all'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Message SMS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            maxLength: 160,
            decoration: InputDecoration(
              hintText:
                  'Ex: Promotion spéciale ce week-end ! -15% sur toute l\'addition.',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B50EC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.send, size: 17),
              label: const Text(
                'Envoyer la campagne',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
