import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/providers/api_providers.dart';
import 'core/errors/error_messages.dart';
import 'core/router/client_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/toast_service.dart';
import 'features/client/providers/app_providers.dart';
import 'features/client/providers/app_startup_provider.dart';
import 'features/client/providers/settings_provider.dart';
import 'l10n/gen/app_localizations.dart';

/// Application racine dédiée à l'espace Client (Web & mobile).
class MivaFidClientApp extends ConsumerWidget {
  const MivaFidClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(clientRouterProvider);
    ref.watch(appStartupProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Synchronisation de la luminosité pour AppColors client
    ref.watch(appBrightnessProvider);

    // Écoute de l'expiration de session client exclusivement
    ref.listen<int>(sessionExpiredProvider, (previous, next) {
      if (previous != null &&
          next > previous &&
          ref.read(authProvider).isAuthenticated) {
        ref.read(authProvider.notifier).clearSession();
        ToastService.showError(ErrorMessages.sessionExpired);
      }
    });

    return MaterialApp.router(
      title: 'Miva-Fid Fidélité',
      debugShowCheckedModeBanner: false,
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
      builder: (context, child) {
        ErrorMessages.bind(AppLocalizations.of(context)!);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

