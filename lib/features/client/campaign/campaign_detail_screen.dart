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
  bool _isBookmarked = false;
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: 'Offre'),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ── Card façon publication Instagram ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.resting,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header façon profil Instagram ────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.cardGradient(AppColors.liningIndigo),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.store,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Offre spéciale',
                                    style: AppTextStyles.label(color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Promotion limitée',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColors.inkMuted(opacity: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppTapScale(
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  LucideIcons.moreHorizontal,
                                  color: AppColors.inkMuted(opacity: 0.6),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Image (ratio 4:5 portrait Instagram) ─────────────
                      if (hasImage)
                        AspectRatio(
                          aspectRatio: 4 / 5,
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
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
                                size: 40,
                              ),
                            ),
                          ),
                        ),

                      if (!hasImage)
                        AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.85),
                                  AppColors.liningPlum,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.megaphone,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.displayLarge(color: Colors.white)
                                      .copyWith(height: 1.15),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ── Action bar ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
                        child: Row(
                          children: [
                            AppTapScale(
                              onTap: () => setState(() => _isLiked = !_isLiked),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  switchInCurve: Curves.easeOutBack,
                                  switchOutCurve: Curves.easeIn,
                                  child: _isLiked
                                      ? const Icon(
                                          LucideIcons.heart,
                                          key: ValueKey('heart-filled'),
                                          color: Color(0xFFFF3B5E),
                                          size: 22,
                                        )
                                      : Icon(
                                          LucideIcons.heart,
                                          key: const ValueKey('heart-outline'),
                                          color: AppColors.ink,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ),
                            AppTapScale(
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  LucideIcons.messageCircle,
                                  color: AppColors.ink,
                                  size: 22,
                                ),
                              ),
                            ),
                            AppTapScale(
                              onTap: () {
                                Share.share(
                                  '${widget.title}\n\n${widget.body}',
                                  subject: widget.title,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  LucideIcons.send,
                                  color: AppColors.ink,
                                  size: 22,
                                ),
                              ),
                            ),
                            const Spacer(),
                            AppTapScale(
                              onTap: () => setState(() => _isBookmarked = !_isBookmarked),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isBookmarked
                                      ? Icon(
                                          LucideIcons.bookmarkCheck,
                                          key: const ValueKey('bm-filled'),
                                          color: AppColors.ink,
                                          size: 22,
                                        )
                                      : Icon(
                                          LucideIcons.bookmark,
                                          key: const ValueKey('bm-outline'),
                                          color: AppColors.ink,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── "J'aime" / mentions ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryTint,
                                border: Border.all(color: AppColors.surfaceCard, width: 1.5),
                              ),
                              child: Icon(
                                LucideIcons.star,
                                color: AppColors.primary,
                                size: 12,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(-6, 0),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.successTint,
                                  border: Border.all(color: AppColors.surfaceCard, width: 1.5),
                                ),
                                child: Icon(
                                  LucideIcons.gift,
                                  color: AppColors.success,
                                  size: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Offre à ne pas manquer',
                                style: AppTextStyles.bodyMedium(
                                  color: AppColors.ink,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Caption (titre + description) ───────────────────
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodyMedium(color: AppColors.ink)
                                .copyWith(height: 1.45),
                            children: [
                              TextSpan(
                                text: 'mivafid_officiel ',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text: widget.title,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text: '\n${widget.body}',
                                style: TextStyle(
                                  color: AppColors.inkMuted(opacity: 0.88),
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Timestamp ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                        child: Text(
                          'OFFRE LIMITÉE DANS LE TEMPS',
                          style: AppTextStyles.eyebrow(
                            color: AppColors.inkMuted(opacity: 0.45),
                          ).copyWith(letterSpacing: 1.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── CTA principal en dehors de la carte ────────────────────
              if (widget.campaignType == 'reward' || widget.rewardId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppButton(
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
                ),
              if (widget.campaignType == 'review' && widget.cardId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppButton(
                    label: "Laisser un avis",
                    onTap: () {
                      context.push('/client/review/${widget.cardId}');
                    },
                    icon: LucideIcons.star,
                    variant: AppButtonVariant.primary,
                  ),
                ),
              if (widget.campaignType == 'referral')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppButton(
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
                ),

              if (widget.campaignType == 'reward' || 
                  widget.rewardId != null || 
                  (widget.campaignType == 'review' && widget.cardId != null) || 
                  widget.campaignType == 'referral') 
                const SizedBox(height: 12),

              // ── Bouton secondaire : contacter / partager ───────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  label: 'Partager l\'offre',
                  onTap: () {
                    Share.share(
                      '${widget.title}\n\n${widget.body}',
                      subject: widget.title,
                    );
                  },
                  icon: LucideIcons.share2,
                  variant: widget.rewardId != null ? AppButtonVariant.ghost : AppButtonVariant.primary,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
