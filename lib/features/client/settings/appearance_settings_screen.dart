import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: t.settingsAppearance,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'THÈME DE L\'APPLICATION',
              style: AppTextStyles.label().copyWith(
                color: AppColors.inkMuted(opacity: 0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choisissez l\'ambiance visuelle adaptée à vos yeux et à votre batterie.',
              style: AppTextStyles.caption().copyWith(
                color: AppColors.inkMuted(opacity: 0.7),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),

            // Cartes de sélection de thème (Changement instantané et fluide)
            _ThemeCard(
              title: t.settingsThemeLight,
              subtitle: 'Couleurs claires et lumineuses pour la journée',
              icon: LucideIcons.sun,
              selected: currentTheme == ThemeMode.light,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light);
              },
            ),
            const SizedBox(height: 12),

            _ThemeCard(
              title: t.settingsThemeDark,
              subtitle: 'Palette sombre et reposante pour la nuit',
              icon: LucideIcons.moon,
              selected: currentTheme == ThemeMode.dark,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
              },
            ),
            const SizedBox(height: 12),

            _ThemeCard(
              title: t.settingsThemeSystem,
              subtitle: 'S\'adapte automatiquement aux réglages de votre téléphone',
              icon: LucideIcons.laptop,
              selected: currentTheme == ThemeMode.system,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryTint
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.inkMuted(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.primary : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.inkMuted(opacity: 0.65),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        LucideIcons.check,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
