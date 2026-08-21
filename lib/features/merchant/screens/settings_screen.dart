import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import '../providers/merchant_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _logout() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Se déconnecter ?',
      message: 'Vous devrez vous reconnecter pour accéder à votre espace marchand.',
      confirmLabel: 'Se déconnecter',
      destructive: true,
    );
    if (!confirmed) return;

    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      context.go('/role-select');
    }
  }

  void _showSubscriptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Abonnement Plan Pro', style: AppTextStyles.h2().copyWith(fontSize: 18)),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: Sp.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Plan Pro', style: AppTextStyles.labelBold().copyWith(fontSize: 16, color: AppColors.merchant)),
                      const Text('15 000 FCFA / mois', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• SMS illimités avec quota mensuel (100 inclus)'),
                  const Text('• Statistiques avancées'),
                  const Text('• Multi-utilisateurs & vitrine personnalisée'),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.merchant,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: Rd.button),
              ),
              child: const Text('Gérer mon abonnement'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(merchantNotifierProvider).value;
    final merchantName = merchant?.name ?? 'Restaurant La Saveur';
    final initials = merchant?.initials ?? 'RL';
    final city = merchant?.address ?? 'Lomé';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Paramètres',
                style: AppTextStyles.h1().copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Sp.md),

              // Profile Card
              InkWell(
                onTap: () => context.push('/merchant/settings/profile'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchantName,
                              style: AppTextStyles.labelBold().copyWith(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Restaurant • $city',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: AppColors.gray400, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Sp.md),

              // "Compléter mon profil 2/5" Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Compléter mon profil',
                          style: AppTextStyles.labelBold().copyWith(fontSize: 14),
                        ),
                        Text(
                          '2/5',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: const LinearProgressIndicator(
                        value: 0.4,
                        color: AppColors.merchant,
                        backgroundColor: Color(0xFFF3F4F6),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProfileTaskRow(
                      label: 'Logo du commerce',
                      onTap: () => context.push('/merchant/settings/profile'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _ProfileTaskRow(
                      label: 'Réseaux sociaux',
                      onTap: () => context.push('/merchant/settings/socials'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _ProfileTaskRow(
                      label: 'Lien d\'avis Google',
                      onTap: () => context.push('/merchant/settings/profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              // COMPTE Section
              const _SectionHeader(title: 'COMPTE'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: LucideIcons.user,
                      title: 'Profil du commerce',
                      onTap: () => context.push('/merchant/settings/profile'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.clock,
                      title: 'Horaires d\'ouverture',
                      onTap: () => context.push('/merchant/settings/hours'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.link,
                      title: 'Réseaux sociaux',
                      trailingText: 'À compléter',
                      onTap: () => context.push('/merchant/settings/socials'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.creditCard,
                      title: 'Abonnement',
                      trailingText: 'Pro',
                      onTap: _showSubscriptionSheet,
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.bell,
                      title: 'Notifications',
                      onTap: () => context.push('/merchant/notifications'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.users,
                      title: 'Équipe',
                      trailingText: '3',
                      onTap: () => AppToast.info(context, 'Gestion de l\'équipe (3 membres)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              // MA CARTE DE FIDÉLITÉ Section
              const _SectionHeader(title: 'MA CARTE DE FIDÉLITÉ'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: LucideIcons.creditCard,
                      title: 'Personnaliser la carte',
                      onTap: () => context.push('/merchant/more/programme'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.gift,
                      title: 'Objectif & récompense',
                      trailingText: '10 visites',
                      onTap: () => context.push('/merchant/more/programme'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.gift,
                      title: 'Programme de fidélité',
                      onTap: () => context.push('/merchant/more/programme'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.scan,
                      title: 'Mon QR code',
                      onTap: () => context.push('/merchant/more/qrcode'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.globe,
                      title: 'Ma vitrine',
                      onTap: () => context.push('/merchant/more/vitrine'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              // ASSISTANCE Section
              const _SectionHeader(title: 'ASSISTANCE'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: LucideIcons.shield,
                      title: 'Confidentialité',
                      onTap: () => AppToast.info(context, 'Politique de confidentialité Miva-Fid'),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _SettingsItem(
                      icon: LucideIcons.helpCircle,
                      title: 'Conditions d\'utilisation',
                      onTap: () => AppToast.info(context, 'Conditions générales d\'utilisation'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),

              // Se Déconnecter Button Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.logOut, color: AppColors.danger, size: 20),
                        const SizedBox(width: 14),
                        Text(
                          'Se déconnecter',
                          style: AppTextStyles.labelBold().copyWith(
                            color: AppColors.danger,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Sp.lg),

              // Version Footer
              Center(
                child: Text(
                  'Miva-Fid v1.0.0',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.gray400,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: Sp.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.caption().copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ProfileTaskRow extends StatelessWidget {
  const _ProfileTaskRow({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gray400,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd().copyWith(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.gray400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gray700, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMd().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.gray500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(LucideIcons.chevronRight, color: AppColors.gray400, size: 18),
          ],
        ),
      ),
    );
  }
}
