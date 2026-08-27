import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../onboarding/models/program_tier.dart';
import '../../onboarding/widgets/loyalty_card_preview.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/tier_editor_form.dart';
import '../../client/providers/settings_provider.dart';

class ProgrammeTiersScreen extends ConsumerStatefulWidget {
  const ProgrammeTiersScreen({super.key});

  @override
  ConsumerState<ProgrammeTiersScreen> createState() => _ProgrammeTiersScreenState();
}

class _ProgrammeTiersScreenState extends ConsumerState<ProgrammeTiersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tierEditorKey = GlobalKey<TierEditorFormState>();
  List<ProgramTier> _tiers = [];
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromMerchant());
  }

  void _initFromMerchant() {
    final restaurant = ref.read(merchantAuthProvider).restaurant;
    final m = ref.read(merchantNotifierProvider).value;
    if (restaurant == null || m == null) return;

    final config = restaurant.loyaltyConfig;
    final loyaltyMode = m.loyaltyMode;
    List<ProgramTier> loaded = [];
    if (config['tiers'] is List) {
      for (final item in config['tiers'] as List) {
        if (item is Map<String, dynamic>) {
          loaded.add(ProgramTier.fromJson(item));
        } else if (item is Map) {
          loaded.add(ProgramTier.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    if (loaded.isEmpty && loyaltyMode != 'cashback') {
      loaded = [ProgramTier(goal: m.stampsRequired, rewardDescription: m.rewardDescription ?? '')];
    }

    setState(() {
      _tiers = loaded;
      _initialized = true;
    });
  }

  String _goalUnit(AppLocalizations t, String loyaltyMode) {
    switch (loyaltyMode) {
      case 'spend':
        return t.merchantProgrammeGoalUnitPoints;
      case 'cashback':
        return t.merchantProgrammeGoalUnitCashback;
      default:
        return t.merchantProgrammeGoalUnitStamps;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = AppLocalizations.of(context)!;

    setState(() => _saving = true);
    final tiers = _tierEditorKey.currentState?.currentTiers() ?? _tiers;

    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'tiers': tiers.map((t) => t.toJson()).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.merchantProgrammeTiersSaveSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.merchantProgrammeTiersSaveError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final loyaltyMode = merchantAsync.value?.loyaltyMode ?? 'stamps';

    if (!_initialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(t.merchantProgrammeTiersLoadingTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.merchantProgrammeTiersTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.merchantProgrammeCardPreviewLabel, style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.sm),
                      const LoyaltyCardPreview(previewStamps: 6),
                      const SizedBox(height: Sp.xl),
                      TierEditorForm(
                        key: _tierEditorKey,
                        initialTiers: _tiers,
                        goalUnit: _goalUnit(t, loyaltyMode),
                        onChanged: (t) => _tiers = t,
                        allowEmpty: loyaltyMode == 'cashback',
                        goalStep: loyaltyMode == 'stamps' ? 5 : 500,
                      ),
                      const SizedBox(height: Sp.md),
                      OutlinedButton.icon(
                        onPressed: () => _tierEditorKey.currentState?.addTier(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppColors.merchant,
                          side: const BorderSide(color: AppColors.merchant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: Text(
                          t.merchantProgrammeAddTierButton,
                          style: AppTextStyles.bodyMd()
                              .copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: Sp.xl),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, MediaQuery.of(context).padding.bottom + Sp.md),
                child: AppButton.primary(t.commonSave,
                    icon: LucideIcons.save, onPressed: _save, loading: _saving),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
