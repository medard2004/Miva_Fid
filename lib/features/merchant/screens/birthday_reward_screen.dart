import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';

/// Réglages de la récompense anniversaire
class BirthdayRewardScreen extends ConsumerStatefulWidget {
  const BirthdayRewardScreen({super.key});

  @override
  ConsumerState<BirthdayRewardScreen> createState() =>
      _BirthdayRewardScreenState();
}

class _BirthdayRewardScreenState extends ConsumerState<BirthdayRewardScreen> {
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
    _titleCtrl = TextEditingController()..addListener(_onFieldChanged);
    _descriptionCtrl = TextEditingController()..addListener(_onFieldChanged);
    _validityCtrl = TextEditingController()..addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
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
      ToastService.showError('Donnez un titre à la récompense anniversaire.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'birthday_reward_enabled': _enabled,
        'birthday_reward_title':
            _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        'birthday_reward_description': _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        if (_validityCtrl.text.trim().isNotEmpty)
          'birthday_reward_validity_days':
              int.tryParse(_validityCtrl.text.trim()),
        'birthday_reward_surprise': _surprise,
      });
      if (mounted) {
        ToastService.showSuccess('Récompense anniversaire enregistrée !');
      }
    } catch (_) {
      if (mounted) {
        ToastService.showError(
            'Impossible d\'enregistrer la récompense anniversaire.');
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
      final birthdayReward = config['birthday_reward'];
      final Map birthday = birthdayReward is Map ? birthdayReward : const {};
      String asText(dynamic v) => v == null ? '' : v.toString();

      _enabled = birthday['enabled'] == true;
      _titleCtrl.text = asText(birthday['title']);
      _descriptionCtrl.text = asText(birthday['description']);
      _validityCtrl.text = asText(birthday['validity_days']);
      _surprise = birthday['surprise'] == true;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
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
          'Récompense anniversaire',
          style: TextStyle(
            fontSize: 18,
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
                        color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.cake,
                              size: 22,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Célébrez l\'anniversaire de vos clients',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "Dans les 30 jours précédant leur anniversaire, vos clients reçoivent automatiquement cette récompense sur leur carte.",
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
                    const SizedBox(height: 20),

                    // ── ACTIVATION CARD ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B50EC)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              size: 18,
                              color: Color(0xFF5B50EC),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activer l\'offre anniversaire',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Générer automatiquement pour chaque anniversaire',
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
                    ),

                    if (_enabled) ...[
                      const SizedBox(height: 20),

                      // ── REWARD FORM ─────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Détails du cadeau',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Titre de la récompense',
                              controller: _titleCtrl,
                              icon: LucideIcons.gift,
                              hint: 'Ex : Dessert offert, Remise de 20%',
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              label: 'Description (optionnel)',
                              controller: _descriptionCtrl,
                              icon: LucideIcons.alignLeft,
                              hint: 'Détail visible par le client',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              label:
                                  'Validité après l\'anniversaire (en jours)',
                              controller: _validityCtrl,
                              icon: LucideIcons.calendarClock,
                              hint: 'Ex : 15 (laisser vide = sans expiration)',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 18),
                            Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    LucideIcons.helpCircle,
                                    size: 18,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Récompense surprise',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Le titre reste masqué jusqu\'à ce que le client vienne réclamer son cadeau.',
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
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── LIVE PREVIEW CARD ───────────────────────────────────
                      Text(
                        'Aperçu pour le client',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B50EC), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B50EC).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        LucideIcons.cake,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Joyeux Anniversaire !',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _validityCtrl.text.trim().isNotEmpty
                                        ? '${_validityCtrl.text.trim()}j restants'
                                        : 'Illimité',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _surprise
                                  ? 'Cadeau surprise 🎁'
                                  : (_titleCtrl.text.trim().isNotEmpty
                                      ? _titleCtrl.text.trim()
                                      : 'Votre récompense'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (_descriptionCtrl.text.trim().isNotEmpty && !_surprise) ...[
                              const SizedBox(height: 4),
                              Text(
                                _descriptionCtrl.text.trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
