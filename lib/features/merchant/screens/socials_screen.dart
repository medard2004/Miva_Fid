import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    _whatsappController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _tiktokController = TextEditingController();
    _googleReviewController = TextEditingController();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: Color(0xFF1E293B),
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
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Réseaux sociaux',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.info, size: 14, color: Color(0xFF5B50EC)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vos clients retrouvent ces liens sur votre vitrine.',
                              style: TextStyle(
                                  fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildGroupCard([
                      _buildField(
                        icon: LucideIcons.phone,
                        label: 'WhatsApp',
                        hint: '+228 90 12 34 56',
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildField(
                        icon: LucideIcons.camera,
                        label: 'Instagram',
                        hint: '@votrecommerce',
                        controller: _instagramController,
                      ),
                      _buildField(
                        icon: LucideIcons.thumbsUp,
                        label: 'Facebook',
                        hint: 'facebook.com/votrecommerce',
                        controller: _facebookController,
                      ),
                      _buildField(
                        icon: LucideIcons.music2,
                        label: 'TikTok',
                        hint: '@votrecommerce',
                        controller: _tiktokController,
                      ),
                      _buildField(
                        icon: LucideIcons.star,
                        label: "Lien d'avis Google",
                        hint: 'g.page/votrecommerce/review',
                        controller: _googleReviewController,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B50EC),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Enregistrer',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          return Column(
            children: [
              entry.value,
              if (entry.key < children.length - 1)
                const Divider(height: 1, indent: 46, color: Color(0xFFF1F5F9)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF475569)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
