import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isUpdatingPlan = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final merchant = ref.watch(merchantNotifierProvider).value;
    final currentPlan = merchant?.plan ?? 'free';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.merchantSubscriptionMyPlan),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlanCard(
              t,
              title: t.merchantSubscriptionPlanStarterName,
              price: '0 F/mois',
              details: '50 clients • 30 SMS',
              planKey: 'free',
              currentPlan: currentPlan,
            ),
            const SizedBox(height: Sp.sm),
            _buildPlanCard(
              t,
              title: t.merchantMoreProTag,
              price: '9 900 F/mois',
              details: '500 clients • 100 SMS',
              planKey: 'pro',
              currentPlan: currentPlan,
            ),
            const SizedBox(height: Sp.sm),
            _buildPlanCard(
              t,
              title: t.merchantSubscriptionPlanBusinessName,
              price: '24 900 F/mois',
              details: 'Illimité • 500 SMS',
              planKey: 'business',
              currentPlan: currentPlan,
            ),
            const SizedBox(height: Sp.md),
            Container(
              padding: const EdgeInsets.all(Sp.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: Rd.card,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.merchantSubscriptionNextInvoiceLabel,
                        style: AppTextStyles.labelBold().copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '15 janvier 2026',
                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    currentPlan == 'business'
                        ? '24 900 F'
                        : currentPlan == 'pro'
                            ? '9 900 F'
                            : '0 F',
                    style: AppTextStyles.mono().copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
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

  Widget _buildPlanCard(
    AppLocalizations t, {
    required String title,
    required String price,
    required String details,
    required String planKey,
    required String currentPlan,
  }) {
    final bool isCurrent = planKey == currentPlan;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Rd.card,
        border: Border.all(
          color: isCurrent ? AppColors.merchant : AppColors.border,
          width: isCurrent ? 2.0 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.merchant.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3().copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: Sp.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.merchant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.merchantSubscriptionCurrentBadge,
                          style: AppTextStyles.caption().copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Sp.xs),
                Text(
                  details,
                  style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: AppTextStyles.mono().copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!isCurrent) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: _isUpdatingPlan
                      ? null
                      : () async {
                          setState(() => _isUpdatingPlan = true);
                          try {
                            await ref.read(merchantNotifierProvider.notifier).updateProgramme({'plan': planKey});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t.merchantSubscriptionPlanChangedSuccess(title)),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t.merchantSubscriptionPlanChangeError(e.toString())),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isUpdatingPlan = false);
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      t.merchantSubscriptionChooseButton,
                      style: AppTextStyles.labelBold().copyWith(
                        color: AppColors.merchant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
