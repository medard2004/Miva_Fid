import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/sms_provider.dart';
import '../../../models/sms_campaign_model.dart';
import 'sms_campaign_screen.dart' show targetLabel;

class SmsCampaignDetailScreen extends ConsumerWidget {
  const SmsCampaignDetailScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final smsState = ref.watch(smsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: smsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(message: '$e'),
          data: (campaigns) {
            final campaign =
                campaigns.where((c) => c.id == campaignId).firstOrNull;
            if (campaign == null) {
              return const _ErrorState(message: 'Campagne introuvable.');
            }
            return _CampaignDetailBody(campaign: campaign);
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert,
                color: AppColors.textSecondary, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignDetailBody extends ConsumerWidget {
  const _CampaignDetailBody({required this.campaign});
  final SmsCampaignModel campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final isPlanned = !campaign.isSent;
    final statusLabel = campaign.isScheduled
        ? 'Programmée'
        : campaign.isDraft
            ? 'Brouillon'
            : 'Envoyée';
    final date = campaign.sentAt ?? campaign.createdAt;
    final dateLabel = campaign.isScheduled && campaign.scheduledAt != null
        ? 'Prévue ${DateFormatter.short(campaign.scheduledAt!)}'
        : DateFormatter.relative(date);
    // 160 caractères = 1 segment SMS-like — approximation cosmétique
    // conservée de l'écran précédent, le message part réellement en push
    // FCM (pas de facturation par segment réelle).
    final segments = (campaign.message.length / 160).ceil().clamp(1, 99);

    return Column(
      children: [
        // ── TOP HEADER ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.chevronLeft,
                    color: AppColors.textPrimary, size: 22),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.message.length > 32
                          ? '${campaign.message.substring(0, 32)}...'
                          : campaign.message,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      targetLabel(campaign.recipientType),
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (campaign.isScheduled)
                IconButton(
                  icon: Icon(LucideIcons.pencil, color: AppColors.textPrimary, size: 20),
                  tooltip: 'Modifier',
                  onPressed: () => context.push('/merchant/sms/new', extra: campaign),
                ),
            ],
          ),
        ),

        // ── BODY CONTENT ─────────────────────────────────────────────
        // Les compteurs envoyé/échec (`delivered_count`/`failed_count`)
        // viennent des jobs FCM async : juste après l'envoi ils sont encore
        // à 0/0 le temps que la queue les traite. Pull-to-refresh recharge
        // `smsNotifierProvider` pour lire l'état à jour.
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF5B50EC),
            onRefresh: () => ref.refresh(smsNotifierProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. STATS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPlanned
                                    ? AppColors.warningTint
                                    : AppColors.successTint,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isPlanned
                                      ? (AppColors.isDark
                                          ? const Color(0xFF4A3A14)
                                          : const Color(0xFFFDE68A))
                                      : (AppColors.isDark
                                          ? const Color(0xFF1F4A38)
                                          : const Color(0xFFBBF7D0)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPlanned
                                        ? LucideIcons.clock
                                        : LucideIcons.circleCheck,
                                    size: 13,
                                    color: isPlanned
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: isPlanned
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF16A34A),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 3 mini stats row — données réelles (`notification_logs`
                        // côté serveur) : pas de suivi d'ouverture des push, donc
                        // pas de "taux d'ouverture" fabriqué ici.
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBox(
                                icon: LucideIcons.users,
                                value: '${campaign.recipientsCount}',
                                label: t.merchantSmsCampaignDetailRecipients,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatBox(
                                icon: LucideIcons.send,
                                value: '${campaign.deliveredCount}',
                                label: t.merchantSmsCampaignDetailSent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatBox(
                                icon: LucideIcons.circleAlert,
                                value: '${campaign.failedCount}',
                                label: 'Échecs',
                              ),
                            ),
                          ],
                        ),
                        if (campaign.recipientsCount > 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Taux de livraison',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${campaign.deliveredCount}/${campaign.recipientsCount}',
                                style: TextStyle(
                                  fontSize: 12.5,
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
                                widthFactor: (campaign.deliveredCount /
                                        campaign.recipientsCount)
                                    .clamp(0, 1)
                                    .toDouble(),
                                child:
                                    Container(color: const Color(0xFF5B50EC)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. MESSAGE ENVOYÉ SECTION
                  Text(
                    t.merchantSmsCampaignDetailMessageTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.message,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${campaign.message.length} caractères',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              '$segments SMS',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
