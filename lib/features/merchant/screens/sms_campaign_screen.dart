import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import '../providers/merchant_provider.dart';
import '../providers/sms_provider.dart';

class SmsCampaignScreen extends ConsumerStatefulWidget {
  const SmsCampaignScreen({super.key});

  @override
  ConsumerState<SmsCampaignScreen> createState() => _SmsCampaignScreenState();
}

class _SmsCampaignScreenState extends ConsumerState<SmsCampaignScreen> {
  static const _mockCampaigns = [
    _MockCampaign(
      title: 'Promo week-end',
      message: 'La Saveur : -15% ce week-end sur tous les plats. À bientôt !',
      stats: '24/24 envoyés • 17 août 2026',
      isSent: true,
    ),
    _MockCampaign(
      title: 'Clients inactifs',
      message: 'Vous nous manquez ! Un tampon offert sur votre prochaine visite.',
      stats: '17/18 envoyés • 9 août 2026',
      isSent: true,
    ),
    _MockCampaign(
      title: 'Récompense disponible',
      message: 'Votre carte est complète : votre plat offert vous attend.',
      stats: '6/6 envoyés • 2 août 2026',
      isSent: true,
    ),
  ];

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

    final smsRemaining = merchant?.smsRemaining ?? 87;
    const smsTotal = 100;
    final progress = (smsRemaining / smsTotal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title and Circular "+" Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campagnes SMS',
                        style: AppTextStyles.h1().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Restez en contact avec vos clients',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _openNewCampaignSheet(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.merchant,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.merchant.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),

              // Quota SMS Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quota SMS du mois',
                          style: AppTextStyles.labelBold().copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$smsRemaining/$smsTotal',
                          style: AppTextStyles.labelBold().copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Amber/Gold Gradient Progress Bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: constraints.maxWidth * progress,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Renouvellement le 1er septembre • Plan Pro',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.md),

              // 2 Stats Cards
              const Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      icon: LucideIcons.users,
                      value: '47',
                      label: 'Contacts joignables',
                    ),
                  ),
                  SizedBox(width: Sp.sm),
                  Expanded(
                    child: _MiniMetricCard(
                      icon: LucideIcons.checkCheck,
                      value: '98 %',
                      label: 'Taux de livraison',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.lg),

              // Historique Header
              Text(
                'HISTORIQUE',
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: Sp.sm),

              // Campaign List
              smsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => _buildCampaignsList(_mockCampaigns),
                data: (campaignList) {
                  final dbCampaigns = campaignList.map((c) => _MockCampaign(
                        title: c.message.length > 20
                            ? '${c.message.substring(0, 20)}...'
                            : c.message,
                        message: c.message,
                        stats: '${c.recipientsCount}/${c.recipientsCount} envoyés • Récemment',
                        isSent: c.status == 'sent',
                      ));

                  final displayList = [...dbCampaigns, ..._mockCampaigns];
                  return _buildCampaignsList(displayList);
                },
              ),
              const SizedBox(height: Sp.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignsList(List<_MockCampaign> list) {
    return Column(
      children: [
        for (int i = 0; i < list.length; i++)
          _CampaignCard(campaign: list[i])
              .animate()
              .fadeIn(
                duration: 350.ms,
                delay: Duration(milliseconds: 80 * i),
              )
              .slideY(begin: 0.05, end: 0),
      ],
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.h1().copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockCampaign {
  const _MockCampaign({
    required this.title,
    required this.message,
    required this.stats,
    required this.isSent,
  });

  final String title;
  final String message;
  final String stats;
  final bool isSent;
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});

  final _MockCampaign campaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                campaign.title,
                style: AppTextStyles.labelBold().copyWith(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  campaign.isSent ? 'Envoyée' : 'Planifiée',
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            campaign.message,
            style: AppTextStyles.bodyMd().copyWith(
              color: const Color(0xFF4B5563),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            campaign.stats,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.gray400,
              fontSize: 11.5,
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
  final _msgCtrl = TextEditingController();
  String _target = 'all';
  bool _loading = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      AppToast.error(context, 'Veuillez saisir un message');
      return;
    }

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Envoyer la campagne SMS ?',
      message: 'Ce message sera envoyé à vos clients.',
      confirmLabel: 'Envoyer',
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      await ref.read(smsNotifierProvider.notifier).sendCampaign(
            message: msg,
            recipientType: _target,
          );
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Campagne SMS envoyée avec succès !');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Erreur: $e');
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
        left: Sp.md,
        right: Sp.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + Sp.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nouvelle Campagne SMS',
                style: AppTextStyles.h2().copyWith(fontSize: 18),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          Text(
            'Destinataires',
            style: AppTextStyles.labelBold().copyWith(fontSize: 13),
          ),
          const SizedBox(height: Sp.xs),
          DropdownButtonFormField<String>(
            initialValue: _target,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous les clients actifs (47)')),
              DropdownMenuItem(value: 'inactive', child: Text('Clients inactifs > 14 jours (12)')),
              DropdownMenuItem(value: 'close_to_reward', child: Text('Proches d\'une récompense (8)')),
            ],
            onChanged: (v) => setState(() => _target = v!),
          ),
          const SizedBox(height: Sp.md),
          Text(
            'Message SMS',
            style: AppTextStyles.labelBold().copyWith(fontSize: 13),
          ),
          const SizedBox(height: Sp.xs),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            maxLength: 160,
            decoration: InputDecoration(
              hintText: 'Ex: Promotion spéciale ce week-end ! -15% sur toute l\'addition.',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: Sp.md),
          AppButton.primary(
            'Envoyer la campagne',
            onPressed: _send,
            loading: _loading,
            icon: LucideIcons.send,
          ),
        ],
      ),
    );
  }
}
