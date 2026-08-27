import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

class ProgrammeRulesScreen extends ConsumerStatefulWidget {
  const ProgrammeRulesScreen({super.key});

  @override
  ConsumerState<ProgrammeRulesScreen> createState() => _ProgrammeRulesScreenState();
}

class _ProgrammeRulesScreenState extends ConsumerState<ProgrammeRulesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fcfaPerPointCtrl = TextEditingController(text: '500');
  
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromMerchant();
    });
  }

  void _initFromMerchant() {
    final restaurant = ref.read(merchantAuthProvider).restaurant;
    if (restaurant != null) {
      final config = restaurant.loyaltyConfig;
      _fcfaPerPointCtrl.text = (int.tryParse(config['fcfa_per_point']?.toString() ?? '') ?? 500).toString();
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _fcfaPerPointCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = AppLocalizations.of(context)!;

    setState(() => _saving = true);

    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'fcfa_per_point': int.tryParse(_fcfaPerPointCtrl.text.trim()) ?? 500,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.merchantProgrammeRulesSaveSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.merchantProgrammeRulesSaveError(e.toString()))),
        );
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
    final merchant = merchantAsync.value;

    if (!_initialized || merchant == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(t.merchantProgrammeRulesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (merchant.loyaltyMode != 'spend') {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(t.merchantProgrammeRulesTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.info, size: 48, color: AppColors.merchant),
                const SizedBox(height: Sp.md),
                Text(
                  t.merchantProgrammeRulesNotApplicable(merchant.loyaltyMode),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.merchantProgrammeRulesTitle),
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
                      Text(t.merchantProgrammeRulesConversionLabel, style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.xs),
                      Text(
                        t.merchantProgrammeRulesConversionSubtitle,
                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: Sp.lg),

                      Container(
                        padding: const EdgeInsets.all(Sp.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: AppInput(
                          label: t.merchantProgrammeRulesInputLabel,
                          hint: t.merchantProgrammeRulesInputHint,
                          controller: _fcfaPerPointCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: LucideIcons.banknote,
                          accentColor: AppColors.merchant,
                          validator: (v) {
                            final parsed = int.tryParse(v?.trim() ?? '');
                            if (parsed == null || parsed <= 0) {
                              return t.merchantProgrammeRulesValidatorError;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, MediaQuery.of(context).padding.bottom + Sp.md),
                child: AppButton.primary(t.commonSave,
                    icon: LucideIcons.save,
                    onPressed: _save,
                    loading: _saving),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
