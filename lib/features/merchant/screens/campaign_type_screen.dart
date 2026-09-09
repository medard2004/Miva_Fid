import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/campaign_model.dart';
import '../providers/sms_campaign_draft_provider.dart';

/// Étape 1 du wizard : choix du type de campagne.
class CampaignTypeScreen extends ConsumerWidget {
  const CampaignTypeScreen({super.key, this.editingCampaign});

  final CampaignModel? editingCampaign;

  static const _types = [
    (CampaignType.promotion, LucideIcons.tag, Color(0xFF5B50EC), Color(0xFFEDE9FE)),
    (CampaignType.reminder, LucideIcons.bellRing, Color(0xFFF59E0B), Color(0xFFFEF3C7)),
    (CampaignType.review, LucideIcons.star, Color(0xFFEC4899), Color(0xFFFCE7F3)),
    (CampaignType.reward, LucideIcons.gift, Color(0xFF10B981), Color(0xFFD1FAE5)),
    (CampaignType.progress, LucideIcons.trendingUp, Color(0xFF3B82F6), Color(0xFFDBEAFE)),
    (CampaignType.referral, LucideIcons.userPlus, Color(0xFF14B8A6), Color(0xFFCCFBF1)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(campaignDraftProvider(editingCampaign));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
        title: Text(
          editingCampaign != null ? 'Modifier la campagne' : 'Nouvelle campagne',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save, size: 20),
            tooltip: 'Sauvegarder en brouillon',
            onPressed: () async {
              try {
                await ref.read(campaignDraftProvider(editingCampaign).notifier).saveAsDraft(1);
                if (context.mounted) {
                  ToastService.showSuccess('Brouillon sauvegardé');
                  context.go('/merchant/sms');
                }
              } catch (e) {
                if (context.mounted) ToastService.showError('$e');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? const Color(0xFF5B50EC)
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quel type de campagne ?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choisissez le type de notification à envoyer à vos clients',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                itemCount: _types.length,
                itemBuilder: (_, i) {
                  final (type, icon, color, bgColor) = _types[i];
                  final selected = draft.type == type;
                  return InkWell(
                    onTap: () {
                      ref.read(campaignDraftProvider(editingCampaign).notifier).setType(type);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.08)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? color : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.isDark
                                  ? color.withValues(alpha: 0.15)
                                  : bgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, size: 18, color: color),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            type.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? color : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Next button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: draft.type == null
                        ? null
                        : () => context.push(
                              '/merchant/campaigns/new/content',
                              extra: editingCampaign,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B50EC),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Suivant',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
