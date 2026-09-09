import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/core/utils/loading_overlay_service.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_section_header.dart';
import 'package:miva_fid/features/client/widgets/shared/user_avatar.dart';

/// Paramètres — apparence (clair/sombre/système), langue, notifications
/// par établissement et déconnexion. Regroupe ce qui encombrait
/// auparavant l'écran Profil pour lui laisser une lecture directe.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmSignOut(
      BuildContext context, WidgetRef ref, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.settingsSignOutConfirmTitle,
            style: AppTextStyles.titleMedium().copyWith(fontSize: 18)),
        content: Text(
          t.settingsSignOutConfirmMessage,
          style:
              AppTextStyles.bodyMedium(color: AppColors.inkMuted(opacity: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.commonCancel,
                style: AppTextStyles.bodyMedium(
                    color: AppColors.inkMuted(opacity: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () async {
              Navigator.pop(context);
              LoadingOverlayService.show(message: t.authLoadingSignOut);
              await ref.read(authProvider.notifier).signOut();
              await LoadingOverlayService.hide();
              if (context.mounted) context.go('/client/auth');
            },
            child: Text(t.settingsSignOut),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(appBrightnessProvider);
    final locale = ref.watch(localeProvider);
    final cards = ref.watch(walletProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppSectionHeader(
              title: t.settingsTitle,
              showDivider: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                children: [
                  if (user != null) ...[
                    AppCard(
                      onTap: () => context.push('/client/profile/edit'),
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
                                  style: AppTextStyles.titleMedium()
                                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user.maskedPhoneNumber,
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
                    const SizedBox(height: 20),
                  ],
                  SectionEyebrow(t.settingsAccount),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ActionRow(
                          icon: LucideIcons.userRoundPen,
                          label: t.profileEditProfile,
                          subtitle: t.editProfileTitle,
                          onTap: () => context.push('/client/profile/edit'),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _ActionRow(
                          icon: LucideIcons.shieldCheck,
                          label: t.editProfileSecurity,
                          subtitle: t.changePasswordTitle,
                          onTap: () => context.push('/client/profile/verify-password'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionEyebrow(t.settingsAppearance),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _OptionRow(
                          icon: LucideIcons.sun,
                          label: t.settingsThemeLight,
                          selected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _OptionRow(
                          icon: LucideIcons.moon,
                          label: t.settingsThemeDark,
                          selected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _OptionRow(
                          icon: LucideIcons.monitor,
                          label: t.settingsThemeSystem,
                          selected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionEyebrow(t.settingsLanguage),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _OptionRow(
                          icon: LucideIcons.languages,
                          label: t.settingsLanguageFrench,
                          selected: locale.languageCode == 'fr',
                          onTap: () => ref
                              .read(localeProvider.notifier)
                              .setLocale(const Locale('fr')),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _OptionRow(
                          icon: LucideIcons.languages,
                          label: t.settingsLanguageEnglish,
                          selected: locale.languageCode == 'en',
                          onTap: () => ref
                              .read(localeProvider.notifier)
                              .setLocale(const Locale('en')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionEyebrow(t.settingsNotifications),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: AppColors.border),
                          _NotifToggleRow(
                            cardId: cards[i].id,
                            name: cards[i].restaurantName,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: t.settingsSignOut,
                    variant: AppButtonVariant.destructive,
                    icon: LucideIcons.logOut,
                    fullWidth: true,
                    height: 48,
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

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTapScale(
      onTap: onTap,
      scaleDown: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium()),
            ),
            if (selected)
              const Icon(LucideIcons.check, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTapScale(
      onTap: onTap,
      scaleDown: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMedium()),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.inkMuted(opacity: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifToggleRow extends ConsumerWidget {
  final String cardId;
  final String name;
  const _NotifToggleRow({required this.cardId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(notificationPrefsProvider.select((p) => p[cardId] ?? true));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(name, style: AppTextStyles.bodyMedium()),
          ),
          _NotificationToggle(
            enabled: enabled,
            onChanged: (value) => ref
                .read(notificationPrefsProvider.notifier)
                .toggle(cardId, value),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: enabled,
      label: 'Notifications',
      onTap: () => onChanged(!enabled),
      child: GestureDetector(
        onTap: () => onChanged(!enabled),
        child: SizedBox(
          width: 64,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 50,
              height: 28,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: enabled ? AppColors.primaryTint : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: enabled ? AppColors.primary : AppColors.border,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: enabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.primary : AppColors.surfaceCard,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    enabled ? LucideIcons.bell : LucideIcons.bellOff,
                    size: 13,
                    color: enabled ? Colors.white : AppColors.inkMuted(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
