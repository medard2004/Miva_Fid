import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';

/// Réglage de l'apparence et de la langue côté marchand — pilote les mêmes
/// providers globaux ([themeModeProvider], [localeProvider]) que l'écran
/// équivalent du module client : un changement ici s'applique donc à toute
/// l'app (marchand, client, onboarding), pas seulement à cet écran.
class LanguageThemeScreen extends ConsumerWidget {
  const LanguageThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.merchantMoreLanguageTheme),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Sp.md),
        children: [
          _SectionLabel(t.settingsAppearance.toUpperCase()),
          const SizedBox(height: 8),
          _GroupCard(
            children: [
              _OptionRow(
                icon: LucideIcons.sun,
                label: t.settingsThemeLight,
                selected: themeMode == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              _OptionRow(
                icon: LucideIcons.moon,
                label: t.settingsThemeDark,
                selected: themeMode == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
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
          const SizedBox(height: 24),
          _SectionLabel(t.settingsLanguage.toUpperCase()),
          const SizedBox(height: 8),
          _GroupCard(
            children: [
              _OptionRow(
                icon: LucideIcons.languages,
                label: t.settingsLanguageFrench,
                selected: locale.languageCode == 'fr',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('fr')),
              ),
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
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: AppTextStyles.caption().copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          return Column(
            children: [
              entry.value,
              if (idx < children.length - 1)
                Divider(height: 1, indent: Sp.md, color: AppColors.border),
            ],
          );
        }).toList(),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.merchant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd().copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(LucideIcons.check, size: 18, color: AppColors.merchant),
          ],
        ),
      ),
    );
  }
}
