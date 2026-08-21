import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';
import '../providers/merchant_provider.dart';

class MerchantSocialsScreen extends ConsumerStatefulWidget {
  const MerchantSocialsScreen({super.key});

  @override
  ConsumerState<MerchantSocialsScreen> createState() => _MerchantSocialsScreenState();
}

class _MerchantSocialsScreenState extends ConsumerState<MerchantSocialsScreen> {
  final _instagramCtrl = TextEditingController(text: '@monsalon');
  final _facebookCtrl = TextEditingController(text: 'facebook.com/monsalon');
  final _tiktokCtrl = TextEditingController(text: '@monsalon');
  final _websiteCtrl = TextEditingController(text: 'https://monsalon.tg');

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = ref.read(merchantNotifierProvider).value;
    if (m != null) {
      if (m.instagram != null && m.instagram!.isNotEmpty) {
        _instagramCtrl.text = m.instagram!;
      }
      if (m.facebook != null && m.facebook!.isNotEmpty) {
        _facebookCtrl.text = m.facebook!;
      }
      if (m.tiktok != null && m.tiktok!.isNotEmpty) {
        _tiktokCtrl.text = m.tiktok!;
      }
    }
  }

  @override
  void dispose() {
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _tiktokCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _saving = false);
      AppToast.success(context, 'Réseaux sociaux enregistrés !');
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
                'Réseaux sociaux',
                style: AppTextStyles.h1().copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ces liens apparaissent sur votre vitrine publique et sur la carte de fidélité.',
                style: AppTextStyles.bodyMd().copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: Sp.lg),

              // Form Card
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
                child: Column(
                  children: [
                    _SocialInputRow(
                      icon: LucideIcons.camera,
                      controller: _instagramCtrl,
                      hint: '@monsalon',
                    ),
                    const SizedBox(height: 14),
                    _SocialInputRow(
                      icon: LucideIcons.share2,
                      controller: _facebookCtrl,
                      hint: 'facebook.com/monsalon',
                    ),
                    const SizedBox(height: 14),
                    _SocialInputRow(
                      icon: LucideIcons.messageCircle,
                      controller: _tiktokCtrl,
                      hint: '@monsalon',
                    ),
                    const SizedBox(height: 14),
                    _SocialInputRow(
                      icon: LucideIcons.globe,
                      controller: _websiteCtrl,
                      hint: 'https://monsalon.tg',
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.xl),

              // Save Button
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

class _SocialInputRow extends StatelessWidget {
  const _SocialInputRow({
    required this.icon,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(icon, size: 18, color: AppColors.gray700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: AppTextStyles.bodyMd().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.gray400, fontSize: 14),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
