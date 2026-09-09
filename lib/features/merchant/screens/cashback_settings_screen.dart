import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/toast_service.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

class CashbackSettingsScreen extends ConsumerStatefulWidget {
  const CashbackSettingsScreen({super.key});

  @override
  ConsumerState<CashbackSettingsScreen> createState() =>
      _CashbackSettingsScreenState();
}

class _CashbackSettingsScreenState extends ConsumerState<CashbackSettingsScreen> {
  late final TextEditingController _percentageCtrl;
  late final TextEditingController _thresholdCtrl;
  late final TextEditingController _expiryCtrl;
  String _tierBasis = 'cumulative';

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _percentageCtrl = TextEditingController();
    _thresholdCtrl = TextEditingController();
    _expiryCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _percentageCtrl.dispose();
    _thresholdCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final percentage =
        double.tryParse(_percentageCtrl.text.trim().replaceAll(',', '.'));
    if (percentage == null || percentage <= 0 || percentage > 100) {
      ToastService.showError('Entrez un pourcentage de cashback entre 0.1 et 100.');
      return;
    }
    final thresholdText = _thresholdCtrl.text.trim();
    final threshold = thresholdText.isEmpty
        ? null
        : double.tryParse(thresholdText.replaceAll(',', '.'));
    if (thresholdText.isNotEmpty && (threshold == null || threshold < 0)) {
      ToastService.showError('Le seuil d\'utilisation doit être un montant FCFA valide.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'cashback_percentage': percentage,
        'cashback_redeem_threshold_fcfa': threshold,
        if (_expiryCtrl.text.trim().isNotEmpty)
          'cashback_expiry_days': int.tryParse(_expiryCtrl.text.trim()),
        'cashback_tier_basis': _tierBasis,
      });
      if (mounted) ToastService.showSuccess('Paramètres cashback enregistrés !');
    } catch (_) {
      if (mounted) {
        ToastService.showError('Impossible d\'enregistrer les paramètres cashback.');
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
      String asText(dynamic v) => v == null ? '' : v.toString();
      _percentageCtrl.text = asText(config['cashback_percentage']).isEmpty
          ? '5'
          : asText(config['cashback_percentage']);
      _thresholdCtrl.text = asText(config['cashback_redeem_threshold_fcfa']);
      _expiryCtrl.text = asText(config['cashback_expiry_days']);
      _tierBasis = config['cashback_tier_basis'] as String? ?? 'cumulative';
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
                      'Paramètres cashback',
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEDF0F7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('POURCENTAGE DE CASHBACK (%)'),
                          const SizedBox(height: 8),
                          Row(
                            children: [3, 5, 10, 15].map((count) {
                              final isSelected =
                                  _percentageCtrl.text == count.toString();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text('$count%'),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF5B50EC),
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  showCheckmark: false,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  onSelected: (_) => setState(
                                      () => _percentageCtrl.text = count.toString()),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _percentageCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: const Icon(LucideIcons.percent,
                                  size: 16, color: Color(0xFF64748B)),
                              hintText: 'Ex: 5',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FD),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFEDF0F7)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFEDF0F7)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildLabel(
                              "SEUIL MINIMUM AVANT UTILISATION (FCFA, OPTIONNEL)"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _thresholdCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: const Icon(LucideIcons.gauge,
                                  size: 16, color: Color(0xFF64748B)),
                              hintText:
                                  'Ex: 10000 (le client doit atteindre 10 000 FCFA avant de pouvoir utiliser son solde)',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FD),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFEDF0F7)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFEDF0F7)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildLabel(
                              "VALIDITÉ DU SOLDE EN JOURS (OPTIONNEL)"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _expiryCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: const Icon(LucideIcons.calendarClock,
                                  size: 16, color: Color(0xFF64748B)),
                              hintText: 'Ex: 365 (vide = pas d\'expiration)',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FD),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFEDF0F7)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFEDF0F7)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
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
                          _buildLabel('BASE DE PROGRESSION DES PALIERS'),
                          const SizedBox(height: 4),
                          const Text(
                            'Détermine à partir de quel montant un palier (niveau) est considéré atteint.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          _TierBasisOption(
                            title: 'Cashback cumulé (recommandé)',
                            subtitle:
                                'Total généré depuis l\'inscription. Utiliser son cashback ne fait jamais perdre un niveau.',
                            selected: _tierBasis == 'cumulative',
                            onTap: () => setState(() => _tierBasis = 'cumulative'),
                          ),
                          const SizedBox(height: 8),
                          _TierBasisOption(
                            title: 'Solde disponible',
                            subtitle:
                                'Solde actuel du client. Le niveau peut redescendre si le solde diminue.',
                            selected: _tierBasis == 'balance',
                            onTap: () => setState(() => _tierBasis = 'balance'),
                          ),
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
}

class _TierBasisOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TierBasisOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF0FF) : const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF5B50EC) : const Color(0xFFEDF0F7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? const Color(0xFF5B50EC) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
