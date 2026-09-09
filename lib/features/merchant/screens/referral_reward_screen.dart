import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/toast_service.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

/// Réglages du système de parrainage à deux récompenses distinctes :
/// 1. Récompense du parrain (Client A) — débloquée après la 1ère visite du filleul
/// 2. Récompense du filleul (Client B) — accordée immédiatement à l'adhésion
class ReferralRewardScreen extends ConsumerStatefulWidget {
  const ReferralRewardScreen({super.key});

  @override
  ConsumerState<ReferralRewardScreen> createState() => _ReferralRewardScreenState();
}

class _ReferralRewardScreenState extends ConsumerState<ReferralRewardScreen> {
  // Config Parrain (Client A)
  late final TextEditingController _referrerLabelCtrl;
  late final TextEditingController _referrerDescCtrl;
  late final TextEditingController _referrerValidityCtrl;
  bool _referrerEnabled = true;
  bool _referrerSurprise = false;

  // Config Filleul (Client B)
  late final TextEditingController _referredLabelCtrl;
  late final TextEditingController _referredDescCtrl;
  late final TextEditingController _referredValidityCtrl;
  bool _referredEnabled = false;
  bool _referredSurprise = false;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _referrerLabelCtrl = TextEditingController();
    _referrerDescCtrl = TextEditingController();
    _referrerValidityCtrl = TextEditingController();

    _referredLabelCtrl = TextEditingController();
    _referredDescCtrl = TextEditingController();
    _referredValidityCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _referrerLabelCtrl.dispose();
    _referrerDescCtrl.dispose();
    _referrerValidityCtrl.dispose();

    _referredLabelCtrl.dispose();
    _referredDescCtrl.dispose();
    _referredValidityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        // Parrain
        'referral_reward_enabled': _referrerEnabled,
        'referral_reward_label':
            _referrerLabelCtrl.text.trim().isEmpty ? null : _referrerLabelCtrl.text.trim(),
        'referral_reward_description':
            _referrerDescCtrl.text.trim().isEmpty ? null : _referrerDescCtrl.text.trim(),
        if (_referrerValidityCtrl.text.trim().isNotEmpty)
          'referral_reward_validity_days': int.tryParse(_referrerValidityCtrl.text.trim()),
        'referral_reward_surprise': _referrerSurprise,

        // Filleul
        'referral_referred_reward_enabled': _referredEnabled,
        'referral_referred_reward_label':
            _referredLabelCtrl.text.trim().isEmpty ? null : _referredLabelCtrl.text.trim(),
        'referral_referred_reward_description':
            _referredDescCtrl.text.trim().isEmpty ? null : _referredDescCtrl.text.trim(),
        if (_referredValidityCtrl.text.trim().isNotEmpty)
          'referral_referred_reward_validity_days': int.tryParse(_referredValidityCtrl.text.trim()),
        'referral_referred_reward_surprise': _referredSurprise,
      });
      if (mounted) ToastService.showSuccess('Récompenses de parrainage enregistrées !');
    } catch (_) {
      if (mounted) {
        ToastService.showError('Impossible d\'enregistrer la configuration de parrainage.');
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
      final referralReward = config['referral_reward'];
      final Map referral = referralReward is Map ? referralReward : const {};
      String asText(dynamic v) => v == null ? '' : v.toString();

      // Parrain
      _referrerEnabled = referral['enabled'] != false;
      _referrerLabelCtrl.text = asText(referral['label']);
      _referrerDescCtrl.text = asText(referral['description']);
      _referrerValidityCtrl.text = asText(referral['validity_days']);
      _referrerSurprise = referral['surprise'] == true;

      // Filleul
      _referredEnabled = referral['referred_enabled'] == true;
      _referredLabelCtrl.text = asText(referral['referred_label']);
      _referredDescCtrl.text = asText(referral['referred_description']);
      _referredValidityCtrl.text = asText(referral['referred_validity_days']);
      _referredSurprise = referral['referred_surprise'] == true;

      _initialized = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(),
                    const SizedBox(height: 16),
                    _buildReferrerConfigCard(),
                    const SizedBox(height: 16),
                    _buildReferredConfigCard(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1E293B), size: 22),
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
              'Récompenses de parrainage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🤝', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Configurez une double récompense : le parrain reçoit son privilège après la première visite validée de son filleul. Le filleul peut également recevoir un avantage dès son inscription par QR code.",
              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferrerConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userCheck, size: 18, color: Color(0xFF5B50EC)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '1. Récompense du Parrain (Client A)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ),
              Switch(
                value: _referrerEnabled,
                onChanged: (v) => setState(() => _referrerEnabled = v),
                activeThumbColor: const Color(0xFF5B50EC),
              ),
            ],
          ),
          const Text(
            'Attribuée au parrain uniquement après la 1ère véritable transaction du filleul.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (_referrerEnabled) ...[
            const SizedBox(height: 14),
            _buildLabel('TITRE DE LA RÉCOMPENSE (PARRAIN)'),
            const SizedBox(height: 8),
            _buildField(
              controller: _referrerLabelCtrl,
              icon: LucideIcons.gift,
              hint: 'Ex : 1 tampon offert (défaut si vide)',
            ),
            const SizedBox(height: 14),
            _buildLabel('DESCRIPTION (OPTIONNEL)'),
            const SizedBox(height: 8),
            _buildField(
              controller: _referrerDescCtrl,
              icon: LucideIcons.alignLeft,
              hint: 'Ex : Valable sur votre prochain achat',
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            _buildLabel('VALIDITÉ APRÈS DÉBLOCAGE (JOURS, OPTIONNEL)'),
            const SizedBox(height: 8),
            _buildField(
              controller: _referrerValidityCtrl,
              icon: LucideIcons.calendarClock,
              hint: 'Ex : 30 (vide = pas d\'expiration)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFEDF0F7)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Récompense surprise 🎁',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      SizedBox(height: 3),
                      Text(
                        'Le titre reste caché au parrain jusqu\'à l\'utilisation.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _referrerSurprise,
                  onChanged: (v) => setState(() => _referrerSurprise = v),
                  activeThumbColor: const Color(0xFF5B50EC),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferredConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userPlus, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '2. Récompense du Filleul (Client B)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ),
              Switch(
                value: _referredEnabled,
                onChanged: (v) => setState(() => _referredEnabled = v),
                activeThumbColor: const Color(0xFF10B981),
              ),
            ],
          ),
          const Text(
            'Accordée immédiatement au filleul dès son inscription via le QR de parrainage.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (_referredEnabled) ...[
            const SizedBox(height: 14),
            _buildLabel('TITRE DE LA RÉCOMPENSE (FILLEUL)'),
            const SizedBox(height: 8),
            _buildField(
              controller: _referredLabelCtrl,
              icon: LucideIcons.gift,
              hint: 'Ex : 10% de réduction immédiate',
            ),
            const SizedBox(height: 14),
            _buildLabel('DESCRIPTION (OPTIONNEL)'),
            const SizedBox(height: 8),
            _buildField(
              controller: _referredDescCtrl,
              icon: LucideIcons.alignLeft,
              hint: 'Ex : Offert pour votre arrivée grâce à votre parrain',
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            _buildLabel('VALIDITÉ APRÈS L\'ADHÉSION (JOURS, OPTIONNEL)'),
            const SizedBox(height: 8),
            _buildField(
              controller: _referredValidityCtrl,
              icon: LucideIcons.calendarClock,
              hint: 'Ex : 30 (vide = pas d\'expiration)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFEDF0F7)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Récompense surprise 🎁',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      SizedBox(height: 3),
                      Text(
                        'Le titre reste caché au filleul jusqu\'à l\'utilisation.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _referredSurprise,
                  onChanged: (v) => setState(() => _referredSurprise = v),
                  activeThumbColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B50EC),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Enregistrer',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.4),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEDF0F7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEDF0F7)),
        ),
      ),
    );
  }
}
