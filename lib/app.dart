import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/providers/api_providers.dart';
import 'core/errors/error_messages.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/toast_service.dart';
import 'features/client/providers/app_providers.dart';
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
    // plutôt que via Theme.of. `appBrightnessProvider` résout le mode
    // choisi contre la luminosité système — et suit ses changements en
    // direct — puis synchronise les tokens d'AppColors ; l'observer ici
    // garantit que l'arbre est reconstruit à chaque bascule.
    ref.watch(appBrightnessProvider);

    // Un 401 remonté par l'intercepteur signale ici que le token stocké n'est
    // plus accepté. On vide la session : la garde du routeur, abonnée à
    // `authProvider`, renvoie alors vers l'écran de connexion.
    ref.listen<int>(sessionExpiredProvider, (previous, next) {
      if (previous != null && next > previous) {
        ref.read(authProvider.notifier).clearSession();
      }
    });

    return MaterialApp.router(
      title: 'Miva-Fid',
      debugShowCheckedModeBanner: false,
      // Canal unique des toasts (succès et erreurs) pour toute l'app.
      scaffoldMessengerKey: ToastService.messengerKey,
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
      // Les messages d'erreur sont produits hors de l'arbre de widgets
      // (providers, intercepteur HTTP) : ils n'ont pas de `BuildContext` pour
      // atteindre `AppLocalizations`. On leur pousse la table de la langue
      // courante ici, au même endroit et pour la même raison que la
      // synchronisation de `AppColors` avec le mode sombre.
      builder: (context, child) {
        ErrorMessages.bind(AppLocalizations.of(context)!);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
