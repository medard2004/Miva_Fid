import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/merchant_provider.dart';
import '../providers/sms_provider.dart';

class SmsCampaignScreen extends ConsumerStatefulWidget {
  const SmsCampaignScreen({super.key});

  @override
  ConsumerState<SmsCampaignScreen> createState() => _SmsCampaignScreenState();
}

class _SmsCampaignScreenState extends ConsumerState<SmsCampaignScreen> {
  final _msgCtrl = TextEditingController();
  String _recipientType = 'all';
  bool _sending = false;

  static const _recipientTypes = [
    ('all', 'Tous les clients', Icons.people_outline),
    ('near_reward', 'Proches d\'une récompense', Icons.star_outline),
    ('inactive', 'Clients inactifs', Icons.schedule_outlined),
  ];

  static const _templates = [
    ('promo', 'Promotion'),
    ('recall', 'Rappel'),
    ('news', 'Nouveauté'),
  ];

  static const _templateMessages = {
    'promo': 'Bonjour [Prénom] ! Profitez de notre offre spéciale chez [Nom Commerce]. Venez nous rendre visite !',
    'recall': 'Bonjour [Prénom], ça fait longtemps ! Votre carte fidélité vous attend chez [Nom Commerce].',
    'news': 'Bonjour [Prénom] ! Découvrez nos nouveautés chez [Nom Commerce]. À bientôt !',
  };

  static const _variables = ['[Prénom]', '[Récompense]', '[Nom Commerce]'];

  void _applyTemplate(String key) {
    _msgCtrl.text = _templateMessages[key] ?? '';
  }

  void _insertVariable(String v) {
    final pos = _msgCtrl.selection.baseOffset;
    final text = _msgCtrl.text;
    _msgCtrl.text = pos < 0
        ? text + v
        : text.substring(0, pos) + v + text.substring(pos);
  }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await ref.read(smsNotifierProvider.notifier).sendCampaign(
      message: _msgCtrl.text.trim(),
      recipientType: _recipientType,
    );
    setState(() => _sending = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campagne envoyée avec succès')));
      context.go('/merchant');
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(merchantNotifierProvider).value;
    final remaining = merchant?.smsRemaining ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Campagne SMS', style: AppTextStyles.h3()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/merchant'),
        ),
        actions: [AppBadge('$remaining SMS', color: AppColors.primary)],
        actionsIconTheme: const IconThemeData(size: 0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Qui reçoit ce SMS ?', style: AppTextStyles.labelBold()),
            const SizedBox(height: Sp.sm),
            ..._recipientTypes.map((r) => GestureDetector(
              onTap: () => setState(() => _recipientType = r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: Sp.sm),
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  color: _recipientType == r.$1 ? AppColors.primaryTint : Colors.white,
                  borderRadius: Rd.card,
                  border: Border.all(
                    color: _recipientType == r.$1 ? AppColors.primary : AppColors.border,
                    width: _recipientType == r.$1 ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(r.$3, color: _recipientType == r.$1 ? AppColors.primary : AppColors.textSecondary, size: 20),
                    const SizedBox(width: Sp.sm),
                    Text(r.$2, style: AppTextStyles.bodyMd().copyWith(
                        color: _recipientType == r.$1 ? AppColors.primary : AppColors.textPrimary)),
                    const Spacer(),
                    if (_recipientType == r.$1)
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            )),
            const SizedBox(height: Sp.lg),
            Text('2. Votre message', style: AppTextStyles.labelBold()),
            const SizedBox(height: Sp.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _templates.map((t) => Padding(
                  padding: const EdgeInsets.only(right: Sp.sm),
                  child: ChoiceChip(
                    label: Text(t.$2),
                    selected: false,
                    onSelected: (_) => _applyTemplate(t.$1),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: Sp.sm),
            TextField(
              controller: _msgCtrl,
              maxLines: 5,
              maxLength: 160,
              style: AppTextStyles.bodyMd(),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bgLight,
                border: OutlineInputBorder(borderRadius: Rd.input,
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                counterStyle: AppTextStyles.mono().copyWith(color: AppColors.textSecondary),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Sp.sm),
            Wrap(
              spacing: Sp.sm,
              children: _variables.map((v) => GestureDetector(
                onTap: () => _insertVariable(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: Rd.pill,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(v, style: AppTextStyles.mono().copyWith(fontSize: 12)),
                ),
              )).toList(),
            ),
            const SizedBox(height: Sp.lg),
            Text('3. Aperçu SMS', style: AppTextStyles.labelBold()),
            const SizedBox(height: Sp.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.all(Sp.sm + Sp.xs),
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_msgCtrl.text.isEmpty ? 'Votre message apparaîtra ici...' : _msgCtrl.text,
                        style: AppTextStyles.bodyMd()),
                    const SizedBox(height: 4),
                    Text('Miva-Fid · ${merchant?.name ?? "Votre Commerce"}',
                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Sp.xl),
            AppButton.merchant('Envoyer maintenant',
                icon: Icons.send_outlined, onPressed: _send, loading: _sending),
            const SizedBox(height: Sp.sm),
            AppButton.outlined('Planifier pour plus tard',
                color: AppColors.merchant, onPressed: () {}),
            const SizedBox(height: Sp.xl),
          ],
        ),
      ),
    );
  }
}
