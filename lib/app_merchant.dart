import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/providers/api_providers.dart';
import 'core/errors/error_messages.dart';
import 'core/router/merchant_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/toast_service.dart';
import 'core/widgets/skeleton_loader.dart';
import 'features/client/providers/app_startup_provider.dart';
import 'features/client/providers/settings_provider.dart';
import 'features/merchant/providers/merchant_auth_provider.dart';
import 'l10n/gen/app_localizations.dart';

/// Application racine dédiée à l'espace Marchand (Android natif).
class MivaFidMerchantApp extends ConsumerWidget {
  const MivaFidMerchantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(merchantRouterProvider);
    final isBootstrapping = ref.watch(appStartupProvider).isLoading;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Synchronisation de la luminosité et du thème
    ref.watch(appBrightnessProvider);

    // Écoute de l'expiration de session marchand exclusivement
    ref.listen<int>(merchantSessionExpiredProvider, (previous, next) {
      if (previous != null &&
          next > previous &&
          ref.read(merchantAuthProvider).isAuthenticated) {
        ref.read(merchantAuthProvider.notifier).clearSession();
        ToastService.showError(ErrorMessages.sessionExpired);
      }
    });

    return MaterialApp.router(
      title: 'Miva-Fid Marchand',
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
        if (isBootstrapping) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(height: 28, width: 180),
                    SizedBox(height: 16),
                    SkeletonCard(height: 150),
                    SizedBox(height: 16),
                    SkeletonLoader(height: 56),
                    SkeletonLoader(height: 56),
                  ],
                ),
              ),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

