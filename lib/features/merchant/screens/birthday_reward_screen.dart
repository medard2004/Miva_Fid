import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/toast_service.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

/// Réglages de la récompense anniversaire (indépendante du mode de
/// fidélité) — voir `SendBirthdayNotifications` côté backend, qui crée
/// automatiquement cette récompense le jour J pour chaque client dont
/// c'est l'anniversaire.
class BirthdayRewardScreen extends ConsumerStatefulWidget {
  const BirthdayRewardScreen({super.key});

  @override
  ConsumerState<BirthdayRewardScreen> createState() => _BirthdayRewardScreenState();
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
          'birthday_reward_validity_days': int.tryParse(_validityCtrl.text.trim()),
        'birthday_reward_surprise': _surprise,
      });
      if (mounted) ToastService.showSuccess('Récompense anniversaire enregistrée !');
    } catch (_) {
      if (mounted) {
        ToastService.showError('Impossible d\'enregistrer la récompense anniversaire.');
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
                      'Récompense anniversaire',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
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
                            child: const Text('🎂', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Dans les 30 jours avant son anniversaire, la "
                              "récompense ci-dessous apparaît automatiquement "
                              "dans les récompenses du client — sur chaque "
                              "carte qu'il a chez vous, quel que soit son "
                              "niveau.",
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Activer la récompense anniversaire',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Switch(
                                value: _enabled,
                                onChanged: (v) => setState(() => _enabled = v),
                                activeThumbColor: const Color(0xFF5B50EC),
                              ),
                            ],
                          ),
                          if (_enabled) ...[
                            const SizedBox(height: 14),
                            _buildLabel('TITRE DE LA RÉCOMPENSE'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _titleCtrl,
                              icon: LucideIcons.gift,
                              hint: 'Ex : Dessert offert',
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('DESCRIPTION (OPTIONNEL)'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _descriptionCtrl,
                              icon: LucideIcons.alignLeft,
                              hint: 'Détail visible par le client',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('VALIDITÉ APRÈS L\'ANNIVERSAIRE (JOURS, OPTIONNEL)'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _validityCtrl,
                              icon: LucideIcons.calendarClock,
                              hint: 'Ex : 7 (vide = pas d\'expiration)',
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
                                      Text(
                                        'Récompense surprise 🎁',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Le titre reste caché au client jusqu\'à ce '
                                        'qu\'il utilise la récompense — vous, vous '
                                        'le voyez toujours.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _surprise,
                                  onChanged: (v) => setState(() => _surprise = v),
                                  activeThumbColor: const Color(0xFF5B50EC),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.4,
      ),
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
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
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
