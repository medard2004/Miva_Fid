import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sp.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paramètres',
                style: AppTextStyles.h1().copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Sp.md),
              
              // Groupe 1 : Navigation principale
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: Rd.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.user,
                      label: 'Compte & Profil',
                      route: '/merchant/more/account',
                    ),
                    const Divider(height: 0, indent: Sp.md),
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.award,
                      label: 'Fidélisation',
                      route: '/merchant/more/programme',
                    ),
                    const Divider(height: 0, indent: Sp.md),
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.creditCard,
                      label: 'Abonnement & Équipe',
                      route: '/merchant/more/subscription',
                    ),
                    const Divider(height: 0, indent: Sp.md),
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.bell,
                      label: 'Préférences',
                      route: '/merchant/more/preferences',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: Sp.lg),
              
              // Groupe 2 : Aide et déconnexion
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: Rd.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.messageCircle,
                      label: 'Support WhatsApp',
                      color: AppColors.success,
                      onTap: () async {
                        final url = Uri.parse('https://wa.me/22899001122');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    const Divider(height: 0, indent: Sp.md),
                    _buildMenuItem(
                      context: context,
                      icon: LucideIcons.logOut,
                      label: 'Se déconnecter',
                      color: AppColors.danger,
                      onTap: () async {
                        final confirmed = await AppDialog.confirm(
                          context,
                          title: 'Se déconnecter ?',
                          message: 'Vous devrez vous reconnecter pour accéder à votre espace marchand.',
                          confirmLabel: 'Se déconnecter',
                          destructive: true,
                        );
                        if (!confirmed) return;
                        await ref.read(merchantAuthProvider.notifier).signOut();
                        if (context.mounted) context.go('/auth/merchant/auth');
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: Sp.xl),
              Center(
                child: Text(
                  'Miva-Fid v1.0.0 • Lomé, Togo',
                  style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: Sp.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? route,
    VoidCallback? onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.primary;
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 20),
      title: Text(
        label,
        style: AppTextStyles.bodyMd().copyWith(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: route != null ? Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary) : null,
      onTap: onTap ?? (route != null ? () => context.go(route) : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 2),
    );
  }
}

