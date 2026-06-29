import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/merchant_provider.dart';

class VitrineScreen extends ConsumerStatefulWidget {
  const VitrineScreen({super.key});

  @override
  ConsumerState<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends ConsumerState<VitrineScreen> {
  int _tab = 0;
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  final _ttCtrl = TextEditingController();
  final _reviewUrlCtrl = TextEditingController();
  bool _showReview = false;
  bool _saving = false;

  static const _days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  final _hoursOpen = List<bool>.filled(7, true);
  final _openTime = List<String>.filled(7, '08:00');
  final _closeTime = List<String>.filled(7, '20:00');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = ref.read(merchantNotifierProvider).value;
      if (m != null) {
        _descCtrl.text = m.description ?? '';
        _phoneCtrl.text = m.phone ?? '';
        _igCtrl.text = m.instagram ?? '';
        _fbCtrl.text = m.facebook ?? '';
        _ttCtrl.text = m.tiktok ?? '';
        _reviewUrlCtrl.text = m.googleReviewUrl ?? '';
        _showReview = m.showReviewButton;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose(); _phoneCtrl.dispose(); _igCtrl.dispose();
    _fbCtrl.dispose(); _ttCtrl.dispose(); _reviewUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(merchantNotifierProvider.notifier).updateProgramme({
      'description': _descCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'instagram': _igCtrl.text.trim(),
      'facebook': _fbCtrl.text.trim(),
      'tiktok': _ttCtrl.text.trim(),
      'google_review_url': _reviewUrlCtrl.text.trim(),
      'show_review_button': _showReview,
    });
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitrine mise à jour')));
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(merchantNotifierProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Ma Vitrine', style: AppTextStyles.h3()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/merchant'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.sm),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: Rd.pill,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: ['Éditeur', 'Aperçu'].asMap().entries.map((e) {
                final selected = _tab == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        borderRadius: Rd.pill,
                      ),
                      child: Text(e.value,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelBold().copyWith(
                              color: selected ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _tab == 0
            ? _EditorView(
                key: const ValueKey('editor'),
                descCtrl: _descCtrl, phoneCtrl: _phoneCtrl,
                igCtrl: _igCtrl, fbCtrl: _fbCtrl, ttCtrl: _ttCtrl,
                reviewUrlCtrl: _reviewUrlCtrl,
                showReview: _showReview,
                onShowReviewChanged: (v) => setState(() => _showReview = v),
                days: _days, hoursOpen: _hoursOpen,
                openTime: _openTime, closeTime: _closeTime,
                onHoursChanged: (i, v) => setState(() => _hoursOpen[i] = v),
                saving: _saving, onSave: _save,
              )
            : _PreviewView(key: const ValueKey('preview'), merchant: merchant),
      ),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView({
    super.key,
    required this.descCtrl, required this.phoneCtrl,
    required this.igCtrl, required this.fbCtrl, required this.ttCtrl,
    required this.reviewUrlCtrl, required this.showReview,
    required this.onShowReviewChanged, required this.days,
    required this.hoursOpen, required this.openTime, required this.closeTime,
    required this.onHoursChanged, required this.saving, required this.onSave,
  });

  final TextEditingController descCtrl, phoneCtrl, igCtrl, fbCtrl, ttCtrl, reviewUrlCtrl;
  final bool showReview;
  final ValueChanged<bool> onShowReviewChanged;
  final List<String> days;
  final List<bool> hoursOpen;
  final List<String> openTime, closeTime;
  final void Function(int, bool) onHoursChanged;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Section('Description', child: AppInput(
                    label: 'Description', controller: descCtrl, maxLines: 3,
                    hint: 'Décrivez votre commerce...')),
                _Section('Contact', child: Column(children: [
                  AppInput(label: 'Téléphone', controller: phoneCtrl,
                      prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                ])),
                _Section('Horaires', child: Column(
                  children: List.generate(7, (i) => _DayRow(
                    day: days[i], isOpen: hoursOpen[i],
                    openTime: openTime[i], closeTime: closeTime[i],
                    onToggle: (v) => onHoursChanged(i, v),
                  )),
                )),
                _Section('Réseaux sociaux', child: Column(children: [
                  AppInput(label: 'Instagram', controller: igCtrl,
                      prefixIcon: Icons.camera_alt_outlined, hint: '@votre_commerce'),
                  AppInput(label: 'Facebook', controller: fbCtrl,
                      prefixIcon: Icons.facebook_outlined, hint: 'facebook.com/votre-page'),
                  AppInput(label: 'TikTok', controller: ttCtrl,
                      prefixIcon: Icons.music_note_outlined, hint: '@votre_compte'),
                ])),
                _Section('Avis clients', child: Column(children: [
                  SwitchListTile.adaptive(
                    value: showReview, onChanged: onShowReviewChanged,
                    title: Text("Afficher le bouton 'Laisser un avis'",
                        style: AppTextStyles.bodyMd()),
                    activeColor: AppColors.primary, contentPadding: EdgeInsets.zero,
                  ),
                  if (showReview) AppInput(label: "Lien Google Avis",
                      controller: reviewUrlCtrl, prefixIcon: Icons.link_outlined,
                      hint: 'https://g.page/...'),
                ])),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Sp.md, 0, Sp.md,
              MediaQuery.of(context).padding.bottom + Sp.md),
          child: AppButton.primary('Enregistrer la vitrine',
              icon: Icons.save_outlined, onPressed: onSave, loading: saving),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.md),
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Rd.card,
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.labelBold()),
        const SizedBox(height: Sp.sm),
        child,
      ]),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.isOpen,
    required this.openTime, required this.closeTime, required this.onToggle});
  final String day;
  final bool isOpen;
  final String openTime, closeTime;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(day, style: AppTextStyles.bodyMd())),
          Switch.adaptive(value: isOpen, onChanged: onToggle, activeColor: AppColors.primary),
          if (isOpen) ...[
            const SizedBox(width: Sp.sm),
            _TimeChip(openTime),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('→', style: TextStyle(color: AppColors.textSecondary))),
            _TimeChip(closeTime),
          ] else
            Text('Fermé', style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip(this.time);
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: Rd.button),
      child: Text(time, style: AppTextStyles.mono().copyWith(fontSize: 12, color: AppColors.primary)),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({super.key, this.merchant});
  final dynamic merchant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        margin: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textPrimary, width: 2),
          borderRadius: Rd.card20,
        ),
        clipBehavior: Clip.hardEdge,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 160,
                color: AppColors.primary.withOpacity(0.8),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(Sp.md),
                child: Text(merchant?.name ?? 'Votre Commerce',
                    style: AppTextStyles.h3().copyWith(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 20, backgroundColor: AppColors.primaryTint,
                            child: Text(merchant?.initials ?? '?',
                                style: AppTextStyles.mono().copyWith(color: AppColors.primary))),
                        const SizedBox(width: Sp.sm),
                        Expanded(child: Text(merchant?.name ?? 'Votre Commerce',
                            style: AppTextStyles.h3())),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.successTint, borderRadius: Rd.pill),
                          child: Text('Ouvert', style: AppTextStyles.caption()
                              .copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: Rd.button)),
                        child: Text('Rejoindre le programme', style: AppTextStyles.labelBold().copyWith(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: Sp.md),
                    Row(
                      children: [
                        Expanded(child: _ContactBtn(Icons.phone_outlined, 'Appeler')),
                        const SizedBox(width: Sp.xs),
                        Expanded(child: _ContactBtn(Icons.chat_outlined, 'WhatsApp')),
                        const SizedBox(width: Sp.xs),
                        Expanded(child: _ContactBtn(Icons.directions_outlined, 'Itinéraire')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  const _ContactBtn(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: Rd.button),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption().copyWith(color: AppColors.primary, fontSize: 10)),
        ],
      ),
    );
  }
}
