import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/client_provider.dart';
import '../providers/loyalty_cards_provider.dart';
import '../providers/rewards_provider.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(clientNotifierProvider).value;
      if (client != null) {
        _nameCtrl.text = client.name;
        _phoneCtrl.text = client.phone ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    await ref.read(clientNotifierProvider.notifier).updateProfile({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });
    setState(() { _saving = false; _editing = false; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')));
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientNotifierProvider);
    final cardsAsync = ref.watch(loyaltyCardsProvider);
    final rewardsAsync = ref.watch(rewardsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sp.md),
          child: clientAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Erreur'),
            data: (client) => Column(
              children: [
                const SizedBox(height: Sp.md),
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryTint,
                      child: Text(
                        client?.initials ?? '?',
                        style: AppTextStyles.display().copyWith(
                            color: AppColors.primary, fontSize: 36),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.md),
                Text(client?.name ?? '', style: AppTextStyles.h2()),
                Text(client?.phone ?? '',
                    style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: Sp.lg),

                // Stats row
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      value: (cardsAsync.value?.length ?? 0).toString(),
                      label: 'Cartes',
                      icon: Icons.credit_card_outlined,
                    )),
                    const SizedBox(width: Sp.sm),
                    Expanded(child: _StatCard(
                      value: (rewardsAsync.value?.where((r) => r.isAvailable).length ?? 0).toString(),
                      label: 'Récompenses',
                      icon: Icons.card_giftcard_outlined,
                    )),
                    const SizedBox(width: Sp.sm),
                    Expanded(child: _StatCard(
                      value: (rewardsAsync.value?.where((r) => r.isUsed).length ?? 0).toString(),
                      label: 'Utilisées',
                      icon: Icons.check_circle_outline,
                    )),
                  ],
                ),
                const SizedBox(height: Sp.lg),

                // Edit profile
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _editing
                      ? Column(
                          key: const ValueKey('edit'),
                          children: [
                            AppInput(label: 'Nom complet', controller: _nameCtrl),
                            AppInput(label: 'Téléphone', controller: _phoneCtrl,
                                keyboardType: TextInputType.phone),
                            AppButton.primary('Enregistrer',
                                onPressed: _saveProfile, loading: _saving),
                            const SizedBox(height: Sp.sm),
                            AppButton.ghost('Annuler',
                                onPressed: () => setState(() => _editing = false)),
                          ],
                        )
                      : AppButton.tint('Modifier mon profil',
                          key: const ValueKey('view'),
                          icon: Icons.edit_outlined,
                          onPressed: () => setState(() => _editing = true)),
                ),
                const SizedBox(height: Sp.lg),

                // Settings
                _ProfileSection('Paramètres', children: [
                  _ProfileTile(Icons.notifications_outlined, 'Notifications', onTap: () {}),
                  _ProfileTile(Icons.security_outlined, 'Sécurité du compte', onTap: () {}),
                  _ProfileTile(Icons.language_outlined, 'Langue', trailing: 'Français', onTap: () {}),
                ]),
                const SizedBox(height: Sp.md),
                _ProfileSection('Support', children: [
                  _ProfileTile(Icons.help_outline, 'Aide', onTap: () {}),
                  _ProfileTile(Icons.star_border_rounded, 'Évaluer l\'app', onTap: () {}),
                ]),
                const SizedBox(height: Sp.md),
                AppButton.danger('Se déconnecter', icon: Icons.logout_rounded,
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) context.go('/role-select');
                    }),
                const SizedBox(height: Sp.md),
                Text('Miva-Fid v1.0.0',
                    style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: Sp.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.sm),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Rd.card,
          border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.monoLg().copyWith(color: AppColors.primary)),
          Text(label, style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection(this.title, {required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Sp.xs, bottom: Sp.xs),
          child: Text(title, style: AppTextStyles.caption()
              .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: Rd.card,
              border: Border.all(color: AppColors.border)),
          child: Column(
            children: children.asMap().entries.map((e) => Column(children: [
              e.value,
              if (e.key < children.length - 1) const Divider(height: 0, indent: Sp.md),
            ])).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile(this.icon, this.label, {this.trailing, this.onTap});
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label, style: AppTextStyles.bodyMd()),
      trailing: trailing != null
          ? Text(trailing!, style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary))
          : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 2),
    );
  }
}
