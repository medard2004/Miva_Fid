import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_radius.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/core/utils/toast_service.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miva_fid/core/api/providers/api_providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    super.key,
    required this.cardId,
  });

  final String cardId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ToastService.showWarning("Veuillez sélectionner au moins une étoile.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = ref.read(apiClientProvider);
      await client.dio.post('/reviews', data: {
        'card_id': widget.cardId,
        'rating': _rating,
        'comment': _commentController.text,
      });
      ToastService.showSuccess("Merci pour votre avis !");
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      ToastService.showError("Erreur lors de l'envoi de l'avis.");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: 'Noter cet établissement'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              
              // ── Header Icon ────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryTint,
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.star,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ── Title & Subtitle ──────────────────────────────────────────
              Text(
                'Comment s\'est passée votre expérience ?',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayLarge(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre avis est précieux pour nous aider à améliorer notre service.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: AppColors.inkMuted()),
              ),
              
              const SizedBox(height: 48),
              
              // ── Stars Selector ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isSelected = starValue <= _rating;
                  return AppTapScale(
                    onTap: () {
                      setState(() {
                        _rating = starValue;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          isSelected ? LucideIcons.star : LucideIcons.star, // The icon changes color
                          key: ValueKey('star_${starValue}_$isSelected'),
                          size: 44,
                          color: isSelected ? AppColors.warning : AppColors.border,
                          // Optional: use a filled star if available in your icon set, but usually setting color is enough
                        ),
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 48),
              
              // ── Comment Field ─────────────────────────────────────────────
              Text(
                'Laisser un commentaire (optionnel)',
                style: AppTextStyles.label(color: AppColors.ink),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Partagez les détails de votre expérience...',
                  hintStyle: AppTextStyles.bodyMedium(color: AppColors.inkMuted(opacity: 0.5)),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // ── Submit Button ─────────────────────────────────────────────
              AppButton(
                label: 'Envoyer mon avis',
                onTap: _submitReview,
                variant: AppButtonVariant.primary,
                icon: _isSubmitting ? null : LucideIcons.send,
                loading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
