import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/errors/error_translator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/toast_service.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/loyalty_card_preview.dart';
import '../../client/providers/settings_provider.dart';

class MerchantReviewScreen extends ConsumerStatefulWidget {
  const MerchantReviewScreen({super.key});

  @override
  ConsumerState<MerchantReviewScreen> createState() =>
      _MerchantReviewScreenState();
}

class _MerchantReviewScreenState extends ConsumerState<MerchantReviewScreen> {
  bool _loading = false;

  Future<void> _createMerchant() async {
    setState(() => _loading = true);

    try {
      final ok = await ref
          .read(onboardingNotifierProvider.notifier)
          .submitLoyaltyProgram();
      if (!ok) throw Exception('refreshFromApi failed');
      await AppHaptics.heavy();
      if (mounted) {
        ToastService.showSuccess(
            'Votre programme a été enregistré avec succès !');
        context.go('/auth/merchant/success');
      }
    } catch (e) {
      debugPrint('Save loyalty program error: $e');
      if (mounted) {
        final error = ErrorTranslator.translate(
          e,
          context: ErrorContext.createLoyaltyProgram,
        );
        final message = error.hasFieldErrors
            ? error.fieldErrors.values.join('\n')
            : error.displayMessage ?? ErrorMessages.profileSaveFailed;
        ToastService.showError(message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'spend':
        return 'Montant dépensé';
      case 'cashback':
        return 'Cashback';
      default:
        return 'Passages / Tampons';
    }
  }

  String _goalLabel(OnboardingState state) {
    switch (state.loyaltyMode) {
      case 'spend':
        return '${state.stampsRequired} points';
      case 'cashback':
        final formattedPercentage = state.cashbackPercentage
                    .truncateToDouble() ==
                state.cashbackPercentage
            ? state.cashbackPercentage.toInt().toString()
            : state.cashbackPercentage.toStringAsFixed(1);
        return '$formattedPercentage%';
      default:
        return '${state.stampsRequired} passages';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final state = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/auth/merchant/step3');
                      }
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Subtitle
                    Text(
                      'Récapitulatif',
                      style: AppTextStyles.h2().copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ).animate().fadeIn(duration: 250.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Vérifiez avant de générer votre QR code.',
                      style: AppTextStyles.bodyMd().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                      ),
                    ).animate(delay: 50.ms).fadeIn(duration: 250.ms),
                    const SizedBox(height: 18),

                    // Loyalty Card Preview
                    LoyaltyCardPreview(
                      previewStamps: (state.stampsRequired * 0.7).round(),
                    ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 20),

                    // Clean Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            label: 'Commerce',
                            value: state.commerceName.isNotEmpty
                                ? state.commerceName
                                : '—',
                          ),
                          const Divider(height: 1),
                          _buildSummaryRow(
                            label: 'Catégorie',
                            value: state.commerceType.isNotEmpty
                                ? state.commerceType
                                : '—',
                          ),
                          const Divider(height: 1),
                          _buildSummaryRow(
                            label: 'Ville',
                            value: state.city.isNotEmpty
                                ? state.city
                                : (state.country.isNotEmpty
                                    ? state.country
                                    : '—'),
                          ),
                          const Divider(height: 1),
                          _buildSummaryRow(
                            label: 'Téléphone',
                            value: state.phone.isNotEmpty ? state.phone : '—',
                          ),
                          const Divider(height: 1),
                          _buildSummaryRow(
                            label: 'Objectif',
                            value: _goalLabel(state),
                          ),
                          const Divider(height: 1),
                          _buildSummaryRow(
                            label: 'Récompense',
                            value: state.rewardDescription.isNotEmpty
                                ? state.rewardDescription
                                : '—',
                          ),
                          const Divider(height: 1),
                          _buildSummaryRow(
                            label: 'Mécanique',
                            value: _modeLabel(state.loyaltyMode),
                          ),
                          const Divider(height: 1),
                          _buildSummaryRow(
                            label: 'Avis Google',
                            value: state.showReviewButton &&
                                    state.googleReviewUrl.isNotEmpty
                                ? 'Activé'
                                : 'Désactivé',
                          ),
                        ],
                      ),
                    ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Buttons (Primary Purple + Secondary Return)
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Button 1: Enregistrer et générer mon QR code
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _createMerchant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B50EC),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor:
                            const Color(0xFF5B50EC).withValues(alpha: 0.6),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.qrCode,
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Enregistrer et générer mon QR code',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Button 2: Retour
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/auth/merchant/step3');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.border, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Retour',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
