import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/color_palette_picker.dart';
import '../../onboarding/widgets/loyalty_card_preview.dart';
import '../providers/merchant_provider.dart';

class ProgrammeDesignScreen extends ConsumerStatefulWidget {
  const ProgrammeDesignScreen({super.key});

  @override
  ConsumerState<ProgrammeDesignScreen> createState() => _ProgrammeDesignScreenState();
}

class _ProgrammeDesignScreenState extends ConsumerState<ProgrammeDesignScreen> {
  Color? _primaryColor;
  bool _saving = false;
  bool _initialized = false;
  bool _showPreview = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromMerchant();
    });
  }

  void _initFromMerchant() {
    final m = ref.read(merchantNotifierProvider).value;
    if (m != null) {
      // On convertit le hex string (ex: #4F46E5) en Color
      String hex = m.colorPrimary.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      _primaryColor = Color(int.parse(hex, radix: 16));
      
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _save() async {
    if (_primaryColor == null) return;
    
    setState(() => _saving = true);

    final hexColor = '#${_primaryColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'color_primary': hexColor,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Design mis à jour avec succès')));
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
    if (!_initialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Apparence')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Apparence de la carte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Aperçu', style: AppTextStyles.labelBold()),
                        Switch(
                          value: _showPreview,
                          onChanged: (val) => setState(() => _showPreview = val),
                          activeThumbColor: AppColors.merchant,
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.xs),
                    if (_showPreview) ...[
                      const LoyaltyCardPreview(previewStamps: 6),
                      const SizedBox(height: Sp.xl),
                    ],

                    Text('Couleur principale', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.xs),
                    Text(
                      'Choisissez la couleur dominante de votre carte de fidélité.',
                      style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: Sp.md),

                    Container(
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ColorPalettePicker(
                        selected: _primaryColor,
                        onColorSelected: (color) {
                          setState(() => _primaryColor = color);
                          // Sync with onboarding provider to update the preview instantly
                          ref.read(onboardingNotifierProvider.notifier).setColorPrimary(color);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, MediaQuery.of(context).padding.bottom + Sp.md),
              child: AppButton.primary(
                'Enregistrer le design',
                icon: LucideIcons.save,
                onPressed: _save,
                loading: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
