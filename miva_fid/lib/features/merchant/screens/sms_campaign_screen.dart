import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/merchant_provider.dart';
import '../providers/sms_provider.dart';

class SmsCampaignScreen extends ConsumerStatefulWidget {
  const SmsCampaignScreen({super.key});

  @override
  ConsumerState<SmsCampaignScreen> createState() => _SmsCampaignScreenState();
}

class _SmsCampaignScreenState extends ConsumerState<SmsCampaignScreen> {
  // Mockup campaigns data to populate if database list is empty
  static const _mockCampaigns = [
    _MockCampaign(
      title: 'Relance inactifs',
      target: 'Inactifs +14j',
      time: 'il y a 2j',
      stats: '12/12 envoyés  •  75% ouverts',
      isSent: true,
    ),
    _MockCampaign(
      title: 'Promo week-end',
      target: 'Tous actifs',
      time: 'il y a 5j',
      stats: '47/47 envoyés  •  81% ouverts',
      isSent: true,
    ),
    _MockCampaign(
      title: 'Anniv. Akosua',
      target: 'Akosua Tetteh',
      time: 'Demain 10h',
      stats: '0/1 envoyés',
      isSent: false, // Planifiée
    ),
    _MockCampaign(
      title: 'Nouveauté menu',
      target: 'VIP Or & Platine',
      time: 'il y a 10j',
      stats: '16/16 envoyés  •  88% ouverts',
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
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final smsAsync = ref.watch(smsNotifierProvider);

    final merchant = merchantAsync.value;


    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Sp.sm),

          // 2. Title and "+ Nouvelle" Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS',
                        style: AppTextStyles.h1().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Campagnes & messages',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openNewCampaignSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.merchant,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: Text(
                      'Nouvelle',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.lg),

            // 3. Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(value: '12', label: 'Envoyées'),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: _StatCard(value: '82%', label: 'Ouverture'),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: _StatCard(value: '143', label: 'Atteints'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.lg),

            // 4. Historique Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: [
                  Text(
                    'Historique',
                    style: AppTextStyles.labelBold().copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '4 campagnes',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.sm),

            // 5. Campaigns List
            Expanded(
              child: smsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Erreur: $err')),
                data: (campaignList) {
                  // Merge Supabase sent campaigns with mockups for visual excellence
                  final dbCampaigns = campaignList.map((c) => _MockCampaign(
                        title: c.message.length > 20 ? '${c.message.substring(0, 20)}...' : c.message,
                        target: c.recipientType == 'all' ? 'Tous actifs' : 'Sélection',
                        time: 'Récemment',
                        stats: '${c.recipientsCount}/${c.recipientsCount} envoyés  •  100% ouverts',
                        isSent: c.status == 'sent',
                      ));

                  final displayList = [...dbCampaigns, ..._mockCampaigns];

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                    itemCount: displayList.length,
                    itemBuilder: (ctx, i) {
                      final c = displayList[i];
                      return _CampaignCard(campaign: c)
                          .animate()
                          .fadeIn(
                            duration: 350.ms,
                            delay: Duration(milliseconds: 80 * i),
                          )
                          .slideY(begin: 0.07, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h1().copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});
  final _MockCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final badgeColor = campaign.isSent ? const Color(0xFF10B981) : const Color(0xFFD97706);
    final badgeBg = campaign.isSent ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final badgeText = campaign.isSent ? 'Envoyée' : 'Planifiée';

    return Container(
      margin: const EdgeInsets.only(bottom: Sp.sm),
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      campaign.title,
                      style: AppTextStyles.labelBold().copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${campaign.target}  •  ${campaign.time}',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  campaign.stats,
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _MockCampaign {
  const _MockCampaign({
    required this.title,
    required this.target,
    required this.time,
    required this.stats,
    required this.isSent,
  });
  final String title;
  final String target;
  final String time;
  final String stats;
  final bool isSent;
}

// "Nouvelle Campagne" Bottom Sheet modal
class _NewCampaignSheet extends ConsumerStatefulWidget {
  const _NewCampaignSheet();

  @override
  ConsumerState<_NewCampaignSheet> createState() => _NewCampaignSheetState();
}

class _NewCampaignSheetState extends ConsumerState<_NewCampaignSheet> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _selectedTarget = 'Tous mes clients (47)';
  bool _sending = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(smsNotifierProvider.notifier).sendCampaign(
            message: _msgCtrl.text.trim(),
            recipientType: 'all',
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campagne envoyée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, Sp.md + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close and Title Header Row
            Row(
              children: [
                Text(
                  'Nouvelle campagne',
                  style: AppTextStyles.h3().copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: Sp.md),

            // NOM field
            Text(
              'NOM',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Ex. Promo week-end',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.bgLight.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.merchant, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: Sp.md),

            // CIBLE field
            Text(
              'CIBLE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                // simple target toggle for mockup demonstration
                setState(() {
                  _selectedTarget = _selectedTarget.contains('Tous')
                      ? 'Clients Or & Platine (26)'
                      : 'Tous mes clients (47)';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedTarget,
                      style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Sp.md),

            // MESSAGE field
            Text(
              'MESSAGE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _msgCtrl,
              maxLines: 4,
              maxLength: 160,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Écrivez votre message...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.bgLight.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                counterText: '', // Hide default counter
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.merchant, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${_msgCtrl.text.length}/160 caractères',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.8)),
                ),
                const Spacer(),
                Text(
                  '${(_msgCtrl.text.length / 160).ceil()} SMS',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.8)),
                ),
              ],
            ),
            const SizedBox(height: Sp.lg),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _msgCtrl.text.trim().isEmpty ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.merchant,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                label: _sending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Envoyer maintenant',
                        style: AppTextStyles.labelBold().copyWith(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Enregistrer brouillon',
                  style: AppTextStyles.labelBold().copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
