import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app_client.dart';
import 'core/router/client_router.dart';
import 'core/services/notification_service.dart';
import 'core/utils/loading_overlay_service.dart';
import 'core/utils/toast_service.dart';
import 'firebase_options.dart';

/// Point d'entrée principal pour l'application Client (Flutter Web).
///
/// Démarre exclusivement sur l'espace client avec support d'accès direct par URL
/// (ex: `/join?code=RESTO123`), sans dépendances natives SQLite ou notifications locales.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ToastService.navigatorKey = clientNavigatorKey;
  LoadingOverlayService.navigatorKey = clientNavigatorKey;

  // Active le routing Web propre (sans '#') pour un deep linking direct par URL
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    unawaited(
      NotificationService()
          .init(isMerchantApp: false, navigatorKey: clientNavigatorKey)
          .catchError((e) {
        if (kDebugMode) debugPrint('NotificationService init erreur: $e');
      }),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase Web non initialisé : $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: MivaFidClientApp()));
}

