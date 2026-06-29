import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/merchant_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchant = ref.watch(merchantNotifierProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Paramètres', style: AppTextStyles.h3()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsSection('Mon compte', children: [
              _SettingsTile(Icons.person_outline, 'Informations personnelles', onTap: () {}),
              _SettingsTile(Icons.lock_outline, 'Changer le mot de passe', onTap: () {}),
              _SettingsTile(Icons.phone_outlined, 'Numéro de téléphone', onTap: () {}),
            ]),
            const SizedBox(height: Sp.md),
            _SettingsSection('Programme', children: [
              _SettingsTile(Icons.workspace_premium_outlined, 'Mon programme fidélité',
                  onTap: () => context.go('/merchant/programme')),
              _SettingsTile(Icons.qr_code_outlined, 'Mon QR Code',
                  onTap: () => context.go('/merchant/qrcode')),
              _SettingsTile(Icons.public_outlined, 'Ma vitrine publique',
                  onTap: () => context.go('/merchant/vitrine')),
            ]),
            const SizedBox(height: Sp.md),
            _SettingsSection('Abonnement', children: [
              ListTile(
                leading: const Icon(Icons.workspace_premium_rounded, color: AppColors.warning),
                title: Text('Plan actuel : ${merchant?.isPro == true ? "Pro" : "Gratuit"}',
                    style: AppTextStyles.bodyMd()),
                subtitle: merchant?.isPro == true
                    ? null
                    : Text('Passez à Pro pour plus de fonctionnalités',
                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                trailing: merchant?.isPro == true
                    ? null
                    : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
                onTap: merchant?.isPro == true ? null : () {},
                contentPadding: const EdgeInsets.symmetric(horizontal: Sp.sm),
              ),
              if (merchant?.isPro != true) ...[
                const Divider(height: 0),
                Padding(
                  padding: const EdgeInsets.all(Sp.sm),
                  child: AppButton.merchant('Passer à Pro', icon: Icons.star_outlined, onPressed: () {}),
                ),
              ],
            ]),
            const SizedBox(height: Sp.md),
            _SettingsSection('Support', children: [
              _SettingsTile(Icons.help_outline, 'Centre d\'aide', onTap: () {}),
              _SettingsTile(Icons.chat_outlined, 'Contacter le support', onTap: () {}),
              _SettingsTile(Icons.star_rate_outlined, 'Évaluer l\'app', onTap: () {}),
            ]),
            const SizedBox(height: Sp.md),
            AppButton.danger(
              'Se déconnecter',
              icon: Icons.logout_rounded,
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/role-select');
              },
            ),
            const SizedBox(height: Sp.md),
            Center(
              child: Text('Miva-Fid v1.0.0 • Lomé, Togo',
                  style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: Sp.xl),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection(this.title, {required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Sp.xs, bottom: Sp.xs),
          child: Text(title,
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Rd.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(children: [
                      e.value,
                      if (e.key < children.length - 1)
                        const Divider(height: 0, indent: Sp.md),
                    ]))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile(this.icon, this.label, {this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label, style: AppTextStyles.bodyMd()),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 2),
    );
  }
}
