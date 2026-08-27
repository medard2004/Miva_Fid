import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';

class _CampaignMock {
  final String id;
  final String title;
  final String status;
  final bool isPlanned;
  final String target;
  final String time;
  final String sentStats;
  final String? openStats;

  const _CampaignMock({
    required this.id,
    required this.title,
    required this.status,
    this.isPlanned = false,
    required this.target,
    required this.time,
    required this.sentStats,
    this.openStats,
  });
}

class SmsCampaignScreen extends ConsumerStatefulWidget {
  const SmsCampaignScreen({super.key});

  @override
  ConsumerState<SmsCampaignScreen> createState() => _SmsCampaignScreenState();
}

class _SmsCampaignScreenState extends ConsumerState<SmsCampaignScreen> {
  static const _mockCampaigns = [
    _CampaignMock(
      id: '1',
      title: 'Relance inactifs',
      status: 'Envoyée',
      target: 'Inactifs +14j',
      time: 'il y a 2j',
      sentStats: '12/12 envoyés',
      openStats: '75% ouverts',
    ),
    _CampaignMock(
      id: '2',
      title: 'Promo week-end',
      status: 'Envoyée',
      target: 'Tous actifs',
      time: 'il y a 5j',
      sentStats: '47/47 envoyés',
      openStats: '81% ouverts',
    ),
    _CampaignMock(
      id: '3',
      title: 'Anniv. Akosua',
      status: 'Planifiée',
      isPlanned: true,
      target: 'Akosua Tetteh',
      time: 'Demain 10h',
      sentStats: '0/1 envoyés',
    ),
    _CampaignMock(
      id: '4',
      title: 'Nouveauté menu',
      status: 'Envoyée',
      target: 'VIP Or & Platine',
      time: 'il y a 10j',
      sentStats: '16/16 envoyés',
      openStats: '88% ouverts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                      color: AppColors.primaryTint,
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
                        Text(
                          t.merchantNavSms,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.merchantSmsCampaignSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/merchant/sms/conversation'),
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.bell,
                            size: 18,
                            color: AppColors.textPrimary,
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
              Row(
                children: [
                  Expanded(
                    child: _buildKpiBox(
                      value: '12',
                      label: t.merchantSmsCampaignSentLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiBox(
                      value: '82%',
                      label: t.merchantSmsCampaignOpenRateLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiBox(
                      value: '143',
                      label: t.merchantSmsCampaignReachedLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── SECTION HISTORIQUE ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.merchantClientDetailHistoryTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    t.merchantSmsCampaignCount('4'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Campaign Cards
              ..._mockCampaigns.map((camp) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => context.push('/merchant/sms/campaign/${camp.id}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                camp.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: camp.isPlanned
                                      ? AppColors.warningTint
                                      : AppColors.successTint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: camp.isPlanned
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
                                      camp.isPlanned
                                          ? LucideIcons.clock
                                          : LucideIcons.circleCheck,
                                      size: 11,
                                      color: camp.isPlanned
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      camp.status,
                                      style: TextStyle(
                                        color: camp.isPlanned
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF16A34A),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${camp.target} • ${camp.time}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                camp.sentStats,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (camp.openStats != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  camp.openStats!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiBox({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
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
}
