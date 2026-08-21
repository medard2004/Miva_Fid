import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';
import '../providers/merchant_provider.dart';

class MerchantProfileScreen extends ConsumerStatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  ConsumerState<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends ConsumerState<MerchantProfileScreen> {
  final _nameCtrl = TextEditingController(text: 'Restaurant La Saveur');
  final _categoryCtrl = TextEditingController(text: 'Restaurant');
  final _descCtrl = TextEditingController(
      text: 'Cuisine togolaise maison, plats du jour et jus frais.');
  final _emailCtrl = TextEditingController(text: 'contact@lasaveur.tg');
  final _phoneCtrl = TextEditingController(text: '+228 90 12 34 56');
  final _whatsappCtrl = TextEditingController(text: '+228 90 12 34 56');
  final _cityCtrl = TextEditingController(text: 'Lomé');
  final _addressCtrl = TextEditingController(text: 'Rue des Cocotiers, Tokoin');
  final _langCtrl = TextEditingController(text: 'Français');

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = ref.read(merchantNotifierProvider).value;
    if (m != null) {
      _nameCtrl.text = m.name;
      _categoryCtrl.text = m.category;
      if (m.description != null && m.description!.isNotEmpty) {
        _descCtrl.text = m.description!;
      }
      if (m.phone != null && m.phone!.isNotEmpty) {
        _phoneCtrl.text = m.phone!;
      }
      if (m.whatsapp != null && m.whatsapp!.isNotEmpty) {
        _whatsappCtrl.text = m.whatsapp!;
      }
      if (m.address != null && m.address!.isNotEmpty) {
        _addressCtrl.text = m.address!;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _langCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _saving = false);
      AppToast.success(context, 'Modifications enregistrées !');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => context.pop(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(LucideIcons.chevronLeft, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Paramètres',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.sm),

              // Title
              Text(
                'Profil du commerce',
                style: AppTextStyles.h1().copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Sp.md),

              // Logo Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF2F7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.camera, color: Color(0xFF6B7280), size: 24),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.merchant,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logo du commerce',
                            style: AppTextStyles.labelBold().copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PNG ou JPG, carré, max 2 Mo.',
                            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary, fontSize: 11.5),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => AppToast.info(context, 'Sélection d\'image'),
                            child: Text(
                              'Changer',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.merchant,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              // Section 1: INFORMATIONS
              const _SectionHeader(title: 'INFORMATIONS'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormFieldItem(label: 'NOM DU COMMERCE', controller: _nameCtrl),
                    const SizedBox(height: 14),
                    _FormFieldItem(label: 'CATÉGORIE', controller: _categoryCtrl),
                    const SizedBox(height: 14),
                    _FormFieldItem(
                      label: 'DESCRIPTION',
                      controller: _descCtrl,
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              // Section 2: CONTACT
              const _SectionHeader(title: 'CONTACT'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormFieldItem(label: 'EMAIL', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _FormFieldItem(label: 'TÉLÉPHONE', controller: _phoneCtrl, keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _FormFieldItem(label: 'WHATSAPP', controller: _whatsappCtrl, keyboardType: TextInputType.phone),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              // Section 3: ADRESSE
              const _SectionHeader(title: 'ADRESSE', icon: LucideIcons.mapPin),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormFieldItem(label: 'VILLE', controller: _cityCtrl),
                    const SizedBox(height: 14),
                    _FormFieldItem(label: 'ADRESSE / QUARTIER', controller: _addressCtrl),
                    const SizedBox(height: 14),
                    _FormFieldItem(label: 'LANGUE DE L\'APPLICATION', controller: _langCtrl),
                  ],
                ),
              ),
              const SizedBox(height: Sp.xl),

              // Primary Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchant,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Enregistrer les modifications',
                          style: AppTextStyles.labelBold().copyWith(color: Colors.white, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: Sp.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            title,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormFieldItem extends StatelessWidget {
  const _FormFieldItem({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            style: AppTextStyles.bodyMd().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
              counterText: maxLength != null ? '${controller.text.length}/$maxLength caractères' : '',
              counterStyle: AppTextStyles.caption().copyWith(fontSize: 11, color: AppColors.gray400),
            ),
          ),
        ),
      ],
    );
  }
}
