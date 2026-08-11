import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/client/core/theme/app_colors.dart' as client_colors;
import 'features/client/providers/settings_provider.dart';
import 'l10n/gen/app_localizations.dart';

class MivaFidApp extends ConsumerWidget {
  const MivaFidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Le module client a son propre design system sensible au mode sombre
    // (lib/features/client/core/theme/app_colors.dart), piloté à la main
    // plutôt que via Theme.of — on le synchronise ici avec le même mode
    // (clair/sombre/système) que celui appliqué au MaterialApp, avant de
    // reconstruire l'arbre.
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedBrightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    client_colors.AppColors.setBrightness(resolvedBrightness);

    return MaterialApp.router(
      title: 'Miva-Fid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
