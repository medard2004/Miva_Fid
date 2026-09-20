import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

class SocialsScreen extends ConsumerStatefulWidget {
  const SocialsScreen({super.key});

  @override
  ConsumerState<SocialsScreen> createState() => _SocialsScreenState();
}

class _SocialsScreenState extends ConsumerState<SocialsScreen> {
  late final TextEditingController _whatsappController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _googleReviewController;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _whatsappController = TextEditingController()..addListener(_onFieldChanged);
    _instagramController = TextEditingController()..addListener(_onFieldChanged);
    _facebookController = TextEditingController()..addListener(_onFieldChanged);
    _tiktokController = TextEditingController()..addListener(_onFieldChanged);
    _googleReviewController = TextEditingController()..addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    _googleReviewController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'whatsapp': _whatsappController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'google_review_url': _googleReviewController.text.trim(),
      });
      if (mounted) ToastService.showSuccess('Réseaux sociaux enregistrés !');
    } catch (_) {
      if (mounted) {
        ToastService.showError("Impossible d'enregistrer les réseaux sociaux.");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);

    if (!_initialized) {
      final account = ref.watch(merchantAuthProvider).restaurant;
      _whatsappController.text = account?.whatsapp ?? '';
      _instagramController.text = account?.instagram ?? '';
      _facebookController.text = account?.facebook ?? '';
      _tiktokController.text = account?.tiktok ?? '';
      _googleReviewController.text =
          account?.loyaltyConfig['google_review_url']?.toString() ?? '';
      _initialized = true;
    }

    final hasAnySocial = _whatsappController.text.trim().isNotEmpty ||
        _instagramController.text.trim().isNotEmpty ||
        _facebookController.text.trim().isNotEmpty ||
        _tiktokController.text.trim().isNotEmpty ||
        _googleReviewController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/merchant/more');
            }
          },
        ),
        title: Text(
          'Réseaux sociaux & Avis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header reassurance info card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B50EC).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B50EC).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.share2,
                              color: Color(0xFF5B50EC),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vitrine digitale & Connexion client',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ces liens s\'affichent sur le pass fidélité de vos clients pour les inciter à vous suivre et vous recommander.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Branded Section - Messagerie & Contact direct
                    _buildSectionHeader(
                      title: 'Messagerie & Réseaux',
                      subtitle: 'Permettez à vos clients de vous contacter directement',
                    ),
                    const SizedBox(height: 10),

                    // WhatsApp Card
                    _buildBrandedCard(
                      icon: LucideIcons.messageCircle,
                      brandColor: const Color(0xFF25D366),
                      title: 'WhatsApp Business',
                      subtitle: 'Commandes, support & échanges directs',
                      hint: '+228 90 12 34 56',
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      helperText: 'Numéro avec l\'indicatif international',
                    ),
                    const SizedBox(height: 12),

                    // Instagram Card
                    _buildBrandedCard(
                      icon: LucideIcons.camera,
                      brandColor: const Color(0xFFE1306C),
                      title: 'Instagram',
                      subtitle: 'Photos de vos produits et stories',
                      hint: '@votrecommerce',
                      controller: _instagramController,
                      prefixText: '@',
                    ),
                    const SizedBox(height: 12),

                    // Facebook Card
                    _buildBrandedCard(
                      icon: LucideIcons.thumbsUp,
                      brandColor: const Color(0xFF1877F2),
                      title: 'Facebook',
                      subtitle: 'Page entreprise ou communauté',
                      hint: 'facebook.com/votrecommerce',
                      controller: _facebookController,
                    ),
                    const SizedBox(height: 12),

                    // TikTok Card
                    _buildBrandedCard(
                      icon: LucideIcons.music2,
                      brandColor: const Color(0xFF0F172A),
                      title: 'TikTok',
                      subtitle: 'Vidéos courtes & tendances',
                      hint: '@votrecommerce',
                      controller: _tiktokController,
                      prefixText: '@',
                    ),
                    const SizedBox(height: 20),

                    // Section - Réputation & Avis
                    _buildSectionHeader(
                      title: 'Réputation en ligne',
                      subtitle: 'Améliorez votre visibilité locale sur Google Maps',
                    ),
                    const SizedBox(height: 10),

                    // Google Reviews Card
                    _buildBrandedCard(
                      icon: LucideIcons.star,
                      brandColor: const Color(0xFFF59E0B),
                      title: 'Lien d\'avis Google (Google Maps)',
                      subtitle: 'Lien direct vers le formulaire d\'avis 5 étoiles',
                      hint: 'https://g.page/r/.../review',
                      controller: _googleReviewController,
                      helperText: 'Vos clients satisfaits pourront laisser un avis en 1 clic',
                    ),
                    const SizedBox(height: 18),

                    // Live Storefront preview
                    if (hasAnySocial) ...[
                      _buildSectionHeader(
                        title: 'Aperçu sur votre vitrine',
                        subtitle: 'Boutons qui seront présentés aux clients',
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (_whatsappController.text.trim().isNotEmpty)
                              _buildPreviewBadge(
                                icon: LucideIcons.messageCircle,
                                color: const Color(0xFF25D366),
                                label: 'WhatsApp',
                              ),
                            if (_instagramController.text.trim().isNotEmpty)
                              _buildPreviewBadge(
                                icon: LucideIcons.camera,
                                color: const Color(0xFFE1306C),
                                label: 'Instagram',
                              ),
                            if (_facebookController.text.trim().isNotEmpty)
                              _buildPreviewBadge(
                                icon: LucideIcons.thumbsUp,
                                color: const Color(0xFF1877F2),
                                label: 'Facebook',
                              ),
                            if (_tiktokController.text.trim().isNotEmpty)
                              _buildPreviewBadge(
                                icon: LucideIcons.music2,
                                color: const Color(0xFF0F172A),
                                label: 'TikTok',
                              ),
                            if (_googleReviewController.text.trim().isNotEmpty)
                              _buildPreviewBadge(
                                icon: LucideIcons.star,
                                color: const Color(0xFFF59E0B),
                                label: 'Avis Google',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Save Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.6),
                    width: 0.5,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B50EC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.check, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandedCard({
    required IconData icon,
    required Color brandColor,
    required String title,
    required String subtitle,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? prefixText,
    String? helperText,
  }) {
    final isFilled = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: brandColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isFilled)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 12,
                    color: Color(0xFF10B981),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: brandColor,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: brandColor, width: 1.5),
              ),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText,
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewBadge({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

