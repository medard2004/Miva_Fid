import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/utils/loading_overlay_service.dart';
import 'package:miva_fid/core/widgets/app_dialog.dart';
import 'package:miva_fid/core/widgets/header_mode_switcher.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_section_header.dart';
import 'package:miva_fid/features/client/widgets/shared/user_avatar.dart';
import 'package:miva_fid/features/merchant/providers/merchant_auth_provider.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Paramètres — apparence, langue, notifications, compte, assistance & déconnexion.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(
      BuildContext context, WidgetRef ref, AppLocalizations t) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: t.settingsSignOutConfirmTitle,
      message: t.settingsSignOutConfirmMessage,
      confirmLabel: t.settingsSignOut,
      cancelLabel: t.commonCancel,
      destructive: true,
      icon: LucideIcons.logOut,
    );

    if (confirmed && context.mounted) {
      LoadingOverlayService.show(message: t.authLoadingSignOut);
      await ref.read(authProvider.notifier).signOut();
      await LoadingOverlayService.hide();
      if (context.mounted) context.go('/client/auth');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(appBrightnessProvider);
    final locale = ref.watch(localeProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final merchantAuth = ref.watch(merchantAuthProvider);
    final isMerchantAuthenticated = merchantAuth.isAuthenticated;

    final themeModeLabel = switch (themeMode) {
      ThemeMode.light => t.settingsThemeLight,
      ThemeMode.dark => t.settingsThemeDark,
      ThemeMode.system => t.settingsThemeSystem,
    };

    final languageLabel = locale.languageCode == 'fr'
        ? t.settingsLanguageFrench
        : t.settingsLanguageEnglish;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppSectionHeader(
              title: t.settingsTitle,
              showDivider: false,
              actions: const [
                HeaderModeSwitcher(isMerchant: false),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                children: [
                  // ── Carte Profil Utilisateur ──────────────────────────
                  if (user != null) ...[
                    GestureDetector(
                      onTap: () => context.push('/client/profile/edit'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            UserAvatar(
                              fullName: user.fullName,
                              photoUrl: user.photoUrl,
                              localImage: auth.localAvatar,
                              radius: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName
                                        : t.profileTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleMedium().copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user.maskedPhoneNumber.isNotEmpty
                                        ? user.maskedPhoneNumber
                                        : ((user.email?.isNotEmpty ?? false)
                                            ? user.email!
                                            : 'Modifier mon profil'),
                                    style: AppTextStyles.bodySmall(
                                      color: AppColors.inkMuted(opacity: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 20,
                              color: AppColors.inkMuted(opacity: 0.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Bouton Configuration Espace Commerçant (Affiché UNIQUEMENT si non configuré) ──
                  if (!isMerchantAuthenticated) ...[
                    GestureDetector(
                      onTap: () => context.push('/onboarding/merchant'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.store,
                                size: 20,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Espace Commerçant',
                                    style: AppTextStyles.bodyMedium().copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Gérer un commerce et fidéliser vos clients',
                                    style: AppTextStyles.caption().copyWith(
                                      color: AppColors.inkMuted(opacity: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── SECTION : MON COMPTE ──────────────────────────────
                  _SectionHeader(title: t.settingsAccount.toUpperCase()),
                  const SizedBox(height: 8),
                  _GroupedContainer(
                    children: [
                      _SettingNavigationRow(
                        icon: LucideIcons.userRoundPen,
                        iconColor: const Color(0xFF3B82F6),
                        title: t.profileEditProfile,
                        onTap: () => context.push('/client/profile/edit'),
                      ),
                      _SettingNavigationRow(
                        icon: LucideIcons.shieldCheck,
                        iconColor: const Color(0xFF10B981),
                        title: t.editProfileSecurity,
                        onTap: () =>
                            context.push('/client/profile/verify-password'),
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── SECTION : PRÉFÉRENCES ─────────────────────────────
                  _SectionHeader(title: t.settingsPreferences.toUpperCase()),
                  const SizedBox(height: 8),
                  _GroupedContainer(
                    children: [
                      _SettingNavigationRow(
                        icon: LucideIcons.bell,
                        iconColor: const Color(0xFFF59E0B),
                        title: t.settingsNotifications,
                        onTap: () =>
                            context.push('/client/settings/notifications'),
                      ),
                      _SettingNavigationRow(
                        icon: LucideIcons.languages,
                        iconColor: const Color(0xFF6366F1),
                        title: t.settingsLanguage,
                        valueBadge: languageLabel,
                        onTap: () => context.push('/client/settings/language'),
                      ),
                      _SettingNavigationRow(
                        icon: LucideIcons.palette,
                        iconColor: const Color(0xFFEC4899),
                        title: t.settingsAppearance,
                        valueBadge: themeModeLabel,
                        onTap: () =>
                            context.push('/client/settings/appearance'),
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── SECTION : ASSISTANCE & INFORMATIONS ───────────────
                  _SectionHeader(title: t.settingsSupport.toUpperCase()),
                  const SizedBox(height: 8),
                  _GroupedContainer(
                    children: [
                      _SettingNavigationRow(
                        icon: LucideIcons.helpCircle,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Centre d\'aide',
                        onTap: () => context.push('/client/settings/help'),
                      ),
                      _SettingNavigationRow(
                        icon: LucideIcons.headset,
                        iconColor: const Color(0xFF06B6D4),
                        title: t.settingsContactUs,
                        onTap: () => context.push('/client/support/contact'),
                      ),
                      _SettingNavigationRow(
                        icon: LucideIcons.bug,
                        iconColor: const Color(0xFFEF4444),
                        title: t.settingsReportBug,
                        onTap: () => context.push('/client/support/report-bug'),
                      ),
                      _SettingNavigationRow(
                        icon: LucideIcons.info,
                        iconColor: const Color(0xFF64748B),
                        title: 'À propos de MivaFid',
                        onTap: () => context.push('/client/settings/about'),
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── BOUTON DÉCONNEXION ────────────────────────────────
                  AppButton(
                    label: t.settingsSignOut,
                    variant: AppButtonVariant.destructive,
                    icon: LucideIcons.logOut,
                    fullWidth: true,
                    height: 50,
                    onTap: () => _confirmSignOut(context, ref, t),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.label().copyWith(
          color: AppColors.inkMuted(opacity: 0.55),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _GroupedContainer extends StatelessWidget {
  final List<Widget> children;
  const _GroupedContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _SettingNavigationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? valueBadge;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingNavigationRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.valueBadge,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  if (valueBadge != null) ...[
                    Text(
                      valueBadge!,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.inkMuted(opacity: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.inkMuted(opacity: 0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 64,
            endIndent: 16,
            color: AppColors.border,
          ),
      ],
    );
  }
}
