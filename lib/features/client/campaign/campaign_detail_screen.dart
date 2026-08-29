import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';

/// Page dédiée au contenu d'une campagne marchand (promo ou info générale) —
/// affiche ce que la notification portait déjà (titre/texte), aucun appel
/// réseau : une campagne SMS n'a pas d'autre contenu structuré aujourd'hui.
class CampaignDetailScreen extends StatelessWidget {
  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
    required this.title,
    required this.body,
  });

  final String campaignId;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppDetailBar(title: 'Offre'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.megaphone, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTextStyles.titleMedium().copyWith(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                body,
                style: AppTextStyles.bodyMedium(color: AppColors.inkMuted(opacity: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
