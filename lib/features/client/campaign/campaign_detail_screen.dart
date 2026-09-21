import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_radius.dart';
import 'package:miva_fid/features/client/core/theme/app_shadows.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

class CampaignDetailScreen extends StatefulWidget {
  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.rewardId,
    this.campaignType,
    this.cardId,
  });

  final String campaignId;
  final String title;
  final String body;
  final String? imageUrl;
  final String? rewardId;
  final String? campaignType;
  final String? cardId;

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppDetailBar(title: 'Détail de l\'offre'),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero Banner / Image ───────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: AppShadows.resting,
                ),
                clipBehavior: Clip.hardEdge,
                child: hasImage
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceMuted,
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceMuted,
                            child: Icon(
                              LucideIcons.imageOff,
                              color: AppColors.inkMuted(opacity: 0.4),
                              size: 36,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.tag,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'OFFRE SPÉCIALE',
                              style: AppTextStyles.eyebrow(color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // ── Carte Détail de l'offre ──────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.sparkles, size: 13, color: AppColors.primary),
                              SizedBox(width: 5),
                              Text(
                                'Offre exclusive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const StatusBadge(
                          label: 'En cours',
                          tone: StatusTone.success,
                          icon: LucideIcons.circleCheck,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.title,
                      style: AppTextStyles.displayMedium().copyWith(fontSize: 20, height: 1.25),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 14),
                    Text(
                      widget.body,
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.ink.withValues(alpha: 0.85),
                      ).copyWith(height: 1.55, fontSize: 14.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Actions ──────────────────────────────────────────────────
              if (widget.campaignType == 'reward' || widget.rewardId != null) ...[
                AppButton(
                  label: "Voir mes récompenses",
                  onTap: () {
                    if (widget.rewardId != null) {
                      context.go('/client/rewards?openReward=${widget.rewardId}');
                    } else {
                      context.go('/client/rewards');
                    }
                  },
                  icon: LucideIcons.gift,
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: 10),
              ],
              if (widget.campaignType == 'review' && widget.cardId != null) ...[
                AppButton(
                  label: "Laisser un avis",
                  onTap: () {
                    context.push('/client/review/${widget.cardId}');
                  },
                  icon: LucideIcons.star,
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: 10),
              ],
              if (widget.campaignType == 'referral') ...[
                AppButton(
                  label: "Parrainer un ami",
                  onTap: () {
                    if (widget.cardId != null) {
                      context.go('/client/referral?cardId=${widget.cardId}');
                    } else {
                      context.go('/client/referral');
                    }
                  },
                  icon: LucideIcons.users,
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: 10),
              ],

              AppButton(
                label: 'Partager cette offre',
                onTap: () {
                  Share.share(
                    '${widget.title}\n\n${widget.body}',
                    subject: widget.title,
                  );
                },
                icon: LucideIcons.share2,
                variant: (widget.campaignType == 'reward' ||
                        widget.rewardId != null ||
                        (widget.campaignType == 'review' && widget.cardId != null) ||
                        widget.campaignType == 'referral')
                    ? AppButtonVariant.secondary
                    : AppButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
