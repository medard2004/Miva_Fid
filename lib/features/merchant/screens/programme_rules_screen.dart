import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
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

    setState(() => _saving = true);

    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'fcfa_per_point': int.tryParse(_fcfaPerPointCtrl.text.trim()) ?? 500,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Règle de conversion mise à jour avec succès')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final merchant = merchantAsync.value;

    if (!_initialized || merchant == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Règles d\'accumulation')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (merchant.loyaltyMode != 'spend') {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Règles d\'accumulation'),
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
                  'Votre programme est configuré en mode "${merchant.loyaltyMode}".\n\n'
                  'Aucune règle de conversion FCFA -> Points n\'est requise.',
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
        title: const Text('Règles d\'accumulation'),
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
                      Text('Conversion FCFA -> Points', style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.xs),
                      Text(
                        'Définissez combien le client doit dépenser pour gagner 1 point.',
                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: Sp.lg),

                      Container(
                        padding: const EdgeInsets.all(Sp.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: AppInput(
                          label: '1 point tous les combien de FCFA ? *',
                          hint: 'Ex: 500',
                          controller: _fcfaPerPointCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: LucideIcons.banknote,
                          accentColor: AppColors.merchant,
                          validator: (v) {
                            final parsed = int.tryParse(v?.trim() ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Veuillez entrer un nombre supérieur à 0';
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
                child: AppButton.primary('Enregistrer',
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
