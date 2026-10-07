import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: t.settingsLanguage,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'CHOIX DE LA LANGUE',
              style: AppTextStyles.label().copyWith(
                color: AppColors.inkMuted(opacity: 0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sélectionnez la langue d\'affichage de l\'application.',
              style: AppTextStyles.caption().copyWith(
                color: AppColors.inkMuted(opacity: 0.7),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _LanguageTile(
                      flag: '🇹🇬',
                      title: 'Français',
                      subtitle: 'Français (Togo / International)',
                      selected: currentLocale.languageCode == 'fr',
                      onTap: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('fr'));
                      },
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                    _LanguageTile(
                      flag: '🇬🇧',
                      title: 'English',
                      subtitle: 'English (US / UK)',
                      selected: currentLocale.languageCode == 'en',
                      onTap: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('en'));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryTint
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 22),
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
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primary : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.inkMuted(opacity: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                )
              else
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
