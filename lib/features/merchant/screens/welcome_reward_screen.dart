import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/toast_service.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

/// Réglages de la récompense de bienvenue — offerte automatiquement au
/// client lorsqu'il rejoint le programme pour la première fois.
class WelcomeRewardScreen extends ConsumerStatefulWidget {
  const WelcomeRewardScreen({super.key});

  @override
  ConsumerState<WelcomeRewardScreen> createState() => _WelcomeRewardScreenState();
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
          'welcome_reward_validity_days': int.tryParse(_validityCtrl.text.trim()),
        'welcome_reward_surprise': _surprise,
      });
      if (mounted) ToastService.showSuccess('Récompense de bienvenue enregistrée !');
    } catch (_) {
      if (mounted) {
        ToastService.showError('Impossible d\'enregistrer la récompense de bienvenue.');
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
                    _buildConfigCard(),
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
              if (context.canPop()) { context.pop(); } else { context.go('/merchant/more'); }
            },
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text('Cadeau de bienvenue',
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
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40, alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: const Text('🎁', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Dès qu'un nouveau client rejoint votre programme, "
              "il reçoit automatiquement cette récompense — "
              "un cadeau de bienvenue qui valorise sa première adhésion.",
              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activer le cadeau de bienvenue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v), activeThumbColor: const Color(0xFF5B50EC)),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 14),
            _buildLabel('TITRE DE LA RÉCOMPENSE'),
            const SizedBox(height: 8),
            _buildField(controller: _titleCtrl, icon: LucideIcons.gift, hint: 'Ex : Boisson offerte'),
            const SizedBox(height: 14),
            _buildLabel('DESCRIPTION (OPTIONNEL)'),
            const SizedBox(height: 8),
            _buildField(controller: _descriptionCtrl, icon: LucideIcons.alignLeft, hint: 'Détail visible par le client', maxLines: 2),
            const SizedBox(height: 14),
            _buildLabel('VALIDITÉ APRÈS L\'ADHÉSION (JOURS, OPTIONNEL)'),
            const SizedBox(height: 8),
            _buildField(controller: _validityCtrl, icon: LucideIcons.calendarClock, hint: 'Ex : 30 (vide = pas d\'expiration)', keyboardType: TextInputType.number),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFEDF0F7)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Récompense surprise 🎁', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      SizedBox(height: 3),
                      Text('Le titre reste caché au client jusqu\'à ce qu\'il utilise la récompense — vous, vous le voyez toujours.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Switch(value: _surprise, onChanged: (v) => setState(() => _surprise = v), activeThumbColor: const Color(0xFF5B50EC)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B50EC), foregroundColor: Colors.white,
          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Enregistrer', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.4));
  }

  Widget _buildField({required TextEditingController controller, required IconData icon, required String hint, TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller, keyboardType: keyboardType, maxLines: maxLines,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        isDense: true, prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true, fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEDF0F7))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEDF0F7))),
      ),
    );
  }
}
