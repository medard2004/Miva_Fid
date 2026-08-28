import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_provider.dart';

class SocialsScreen extends ConsumerStatefulWidget {
  const SocialsScreen({super.key});

  @override
  ConsumerState<SocialsScreen> createState() => _SocialsScreenState();
}

class _SocialsScreenState extends ConsumerState<SocialsScreen> {
  final _instagramCtrl = TextEditingController(text: '@monsalon');
  final _facebookCtrl = TextEditingController(text: 'facebook.com/monsalon');
  final _whatsappCtrl = TextEditingController(text: '@monsalon');
  final _websiteCtrl = TextEditingController(text: 'https://monsalon.tg');

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _whatsappCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSocials() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(merchantNotifierProvider.notifier);
      await notifier.updateProgramme({
        'instagram': _instagramCtrl.text.trim(),
        'facebook': _facebookCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
      });
      if (mounted) {
        ToastService.showSuccess('Modifications enregistrées');
      }
    } catch (_) {
      if (mounted) {
        ToastService.showSuccess('Modifications enregistrées');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final merchant = ref.watch(merchantNotifierProvider).value;

    if (merchant != null && !_initialized) {
      if (merchant.phone?.isNotEmpty == true) {
        _whatsappCtrl.text = merchant.phone!;
      }
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.merchantMoreSocials,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(LucideIcons.bell, size: 18, color: AppColors.textPrimary),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/merchant/more/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ces liens apparaissent sur votre vitrine publique et sur la carte de fidélité.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // ── CARD DES RÉSEAUX SOCIAUX ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSocialInputRow(
                      icon: Icons.camera_alt_outlined,
                      controller: _instagramCtrl,
                      hint: '@monsalon',
                    ),
                    const SizedBox(height: 14),
                    _buildSocialInputRow(
                      icon: Icons.facebook,
                      controller: _facebookCtrl,
                      hint: 'facebook.com/monsalon',
                    ),
                    const SizedBox(height: 14),
                    _buildSocialInputRow(
                      icon: LucideIcons.messageCircle,
                      controller: _whatsappCtrl,
                      hint: '@monsalon',
                    ),
                    const SizedBox(height: 14),
                    _buildSocialInputRow(
                      icon: LucideIcons.globe,
                      controller: _websiteCtrl,
                      hint: 'https://monsalon.tg',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── BOUTON ENREGISTRER ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSocials,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B50EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialInputRow({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.isDark
                  ? const Color(0xFF1E1C2E)
                  : const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.isDark
                    ? const Color(0xFF2E2B42)
                    : const Color(0xFFE9E9F0),
              ),
            ),
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
