import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';

/// Réglages de la récompense de bienvenue — offerte automatiquement au
/// client lorsqu'il rejoint le programme pour la première fois.
class WelcomeRewardScreen extends ConsumerStatefulWidget {
  const WelcomeRewardScreen({super.key});

  @override
  ConsumerState<WelcomeRewardScreen> createState() =>
      _WelcomeRewardScreenState();
}

class _WelcomeRewardScreenState extends ConsumerState<WelcomeRewardScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _validityCtrl;
  bool _enabled = false;
  bool _surprise = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _validityCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _validityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_enabled && _titleCtrl.text.trim().isEmpty) {
      ToastService.showError('Donnez un titre à la récompense de bienvenue.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'welcome_reward_enabled': _enabled,
        'welcome_reward_title':
            _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        'welcome_reward_description': _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        if (_validityCtrl.text.trim().isNotEmpty)
          'welcome_reward_validity_days':
              int.tryParse(_validityCtrl.text.trim()),
        'welcome_reward_surprise': _surprise,
      });
      if (mounted) {
        ToastService.showSuccess('Cadeau de bienvenue enregistré !');
      }
    } catch (_) {
      if (mounted) {
        ToastService.showError(
            'Impossible d\'enregistrer le cadeau de bienvenue.');
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
      final config = account?.loyaltyConfig ?? const {};
      final welcomeReward = config['welcome_reward'];
      final Map welcome = welcomeReward is Map ? welcomeReward : const {};
      String asText(dynamic v) => v == null ? '' : v.toString();

      _enabled = welcome['enabled'] == true;
      _titleCtrl.text = asText(welcome['title']);
      _descriptionCtrl.text = asText(welcome['description']);
      _validityCtrl.text = asText(welcome['validity_days']);
      _surprise = welcome['surprise'] == true;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: AppColors.textPrimary, size: 22),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/merchant/more');
            }
          },
        ),
        title: Text(
          'Cadeau de bienvenue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _enabled
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _enabled
                        ? const Color(0xFF10B981)
                        : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _enabled ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _enabled
                        ? const Color(0xFF10B981)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HERO BANNER ─────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B50EC)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('🎁',
                                style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offre d\'accueil immédiate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "Offerte automatiquement dès qu'un nouveau client rejoint votre programme de fidélité pour la 1ère fois.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── CONFIGURATION CARD ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Activer le cadeau de bienvenue',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Distribuer automatiquement à l\'adhésion',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _enabled,
                                activeTrackColor: const Color(0xFF5B50EC),
                                onChanged: (v) => setState(() => _enabled = v),
                              ),
                            ],
                          ),
                          if (_enabled) ...[
                            const SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Titre de la récompense',
                              controller: _titleCtrl,
                              icon: LucideIcons.gift,
                              hint: 'Ex : Boisson offerte, 10% de réduction',
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              label: 'Description (optionnel)',
                              controller: _descriptionCtrl,
                              icon: LucideIcons.alignLeft,
                              hint: 'Conditions ou détails visibles par le client',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              label: 'Durée de validité (en jours, optionnel)',
                              controller: _validityCtrl,
                              icon: LucideIcons.calendarClock,
                              hint: 'Ex : 30 (laisser vide pour sans expiration)',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Récompense surprise 🎁',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Le titre reste caché jusqu\'à ce que le client réclame son cadeau.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          height: 1.35,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _surprise,
                                  activeTrackColor: const Color(0xFF5B50EC),
                                  onChanged: (v) =>
                                      setState(() => _surprise = v),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BOTTOM SAVE BAR ──────────────────────────────────────────
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
                            Icon(LucideIcons.check,
                                size: 16, color: Colors.white),
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
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
              borderSide:
                  const BorderSide(color: Color(0xFF5B50EC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
