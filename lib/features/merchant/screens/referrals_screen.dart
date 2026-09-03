import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../client/providers/settings_provider.dart';

/// Un parrainage tel que renvoyé par `GET /merchant/referrals` — parrain,
/// filleul, statut, récompense attribuée. Reste local à cet écran (pas de
/// modèle partagé avec le client, dont la vue est scopée différemment).
class _MerchantReferral {
  final String referrerName;
  final String referredName;
  final bool isValidated;
  final DateTime? createdAt;
  final String? rewardTitle;
  final String? referredRewardTitle;

  const _MerchantReferral({
    required this.referrerName,
    required this.referredName,
    required this.isValidated,
    this.createdAt,
    this.rewardTitle,
    this.referredRewardTitle,
  });

  factory _MerchantReferral.fromJson(Map<String, dynamic> json) {
    final referrer = json['referrer_client'] as Map<String, dynamic>?;
    final referred = json['referred_client'] as Map<String, dynamic>?;
    final reward = json['reward'] as Map<String, dynamic>?;
    final referredReward = json['referred_reward'] as Map<String, dynamic>?;
    return _MerchantReferral(
      referrerName: referrer?['first_name'] as String? ?? '—',
      referredName: referred?['first_name'] as String? ?? '—',
      isValidated: json['status'] == 'validated',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      rewardTitle: reward?['title'] as String?,
      referredRewardTitle: referredReward?['title'] as String?,
    );
  }
}

/// Liste des parrainages de l'établissement — qui a parrainé qui, statut,
/// récompense attribuée. Voir `ReferralController::forRestaurant` côté API.
class ReferralsScreen extends ConsumerStatefulWidget {
  const ReferralsScreen({super.key});

  @override
  ConsumerState<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends ConsumerState<ReferralsScreen> {
  late Future<List<_MerchantReferral>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_MerchantReferral>> _load() async {
    final rows =
        await ref.read(merchantDashboardServiceProvider).referrals();
    return rows.map(_MerchantReferral.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft,
                        color: Color(0xFF1E293B), size: 22),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/merchant/more');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Parrainages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_MerchantReferral>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Impossible de charger les parrainages.'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _future = _load()),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }
                  final referrals = snapshot.data ?? const [];
                  if (referrals.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun parrainage pour le moment.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      final next = _load();
                      setState(() => _future = next);
                      await next;
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: referrals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _ReferralRow(referral: referrals[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralRow extends StatelessWidget {
  final _MerchantReferral referral;
  const _ReferralRow({required this.referral});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${referral.referrerName} → ${referral.referredName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  referral.isValidated
                      ? 'Validé${referral.rewardTitle != null ? ' — Parrain : ${referral.rewardTitle}' : ''}'
                      : 'En attente'
                          '${referral.referredRewardTitle != null ? ' — Filleul : ${referral.referredRewardTitle}' : ''}'
                          '${referral.createdAt != null ? ' (depuis le ${DateFormat('dd/MM/yyyy').format(referral.createdAt!)})' : ''}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: referral.isValidated
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              referral.isValidated ? 'Validé' : 'En attente',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: referral.isValidated
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
