import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/merchant_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../../client/providers/settings_provider.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/toast_service.dart';
import '../widgets/merchant_avatar.dart';

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
  bool _uploadingLogo = false;
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

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (!mounted || file == null) return;

    setState(() => _uploadingLogo = true);
    final ok = await ref.read(merchantAuthProvider.notifier).uploadLogo(File(file.path));
    if (!mounted) return;
    if (ok) {
      ToastService.showSuccess('Logo mis à jour avec succès');
    } else {
      ToastService.showError('Impossible de mettre à jour le logo. Réessayez.');
    }
    setState(() => _uploadingLogo = false);
  }

  Future<void> _removeLogo() async {
    setState(() => _uploadingLogo = true);
    final ok = await ref.read(merchantAuthProvider.notifier).deleteLogo();
    if (!mounted) return;
    if (ok) {
      ToastService.showSuccess('Logo supprimé avec succès');
    } else {
      ToastService.showError('Impossible de supprimer le logo. Réessayez.');
    }
    setState(() => _uploadingLogo = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final merchantState = ref.watch(merchantAuthProvider);
    final merchant = merchantAsync.value;

    if (merchant != null && !_initialized) {
      _nameController.text = merchant.name;
      _phoneController.text = merchant.phone ?? '';
      _emailController.text = merchantState.restaurant?.email ?? '';
      _initialized = true;
    }

    if (merchantAsync.isLoading && merchant == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.merchant),
        ),
      );
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
                // Photo de profil / Logo section
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          MerchantAvatar(
                            logoUrl: merchant?.logoUrl,
                            initials: merchant?.initials ?? 'RS',
                            radius: 44,
                          ),
                          if (_uploadingLogo)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: Sp.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _uploadingLogo ? null : _pickLogo,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(LucideIcons.camera, size: 16, color: AppColors.merchant),
                            label: Text(
                              merchant?.logoUrl != null && merchant!.logoUrl!.isNotEmpty
                                  ? 'Changer la photo'
                                  : 'Ajouter une photo',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (merchant?.logoUrl != null && merchant!.logoUrl!.isNotEmpty) ...[
                            const SizedBox(width: Sp.xs),
                            IconButton(
                              onPressed: _uploadingLogo ? null : _removeLogo,
                              tooltip: 'Supprimer le logo',
                              icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.lg),
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
                const SizedBox(height: Sp.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.push('/merchant/more/change-password'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      'Changer le mot de passe',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.merchant,
                        fontWeight: FontWeight.w700,
                      ),
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
