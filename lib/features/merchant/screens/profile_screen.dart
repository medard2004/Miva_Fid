import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/merchant_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  String _selectedLanguage = 'Français';
  bool _isSavingProfile = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final merchant = ref.watch(merchantNotifierProvider).value;

    if (merchant != null && !_initialized) {
      _nameController.text = merchant.name;
      _phoneController.text = merchant.phone ?? '';
      _emailController.text =
          ref.read(merchantAuthProvider).restaurant?.email ?? '';
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Container(
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Rd.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputLabel('NOM DU COMMERCE'),
                const SizedBox(height: Sp.xs),
                TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    fillColor: AppColors.background,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                    border: const OutlineInputBorder(
                      borderRadius: Rd.input,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: Sp.md),
                _buildInputLabel('EMAIL'),
                const SizedBox(height: Sp.xs),
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                  decoration: InputDecoration(
                    fillColor: AppColors.background.withValues(alpha: 0.5),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                    border: const OutlineInputBorder(
                      borderRadius: Rd.input,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: Sp.md),
                _buildInputLabel('TÉLÉPHONE'),
                const SizedBox(height: Sp.xs),
                TextFormField(
                  controller: _phoneController,
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    fillColor: AppColors.background,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                    border: const OutlineInputBorder(
                      borderRadius: Rd.input,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: Sp.md),
                _buildInputLabel('LANGUE'),
                const SizedBox(height: Sp.xs),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  icon: Icon(LucideIcons.chevronDown, color: AppColors.textSecondary),
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    fillColor: AppColors.background,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                    border: const OutlineInputBorder(
                      borderRadius: Rd.input,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Français', 'English'].map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLanguage = val);
                    }
                  },
                ),
                const SizedBox(height: Sp.lg),
                AppButton.merchant(
                  'Enregistrer',
                  loading: _isSavingProfile,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isSavingProfile = true);
                    try {
                      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
                        'name': _nameController.text.trim(),
                        'phone': _phoneController.text.trim(),
                      });
                      _initialized = false;
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profil mis à jour avec succès'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la mise à jour : $e'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSavingProfile = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.caption().copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}
