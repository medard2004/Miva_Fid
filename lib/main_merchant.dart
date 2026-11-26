import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app_merchant.dart';
import 'core/router/merchant_router.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

/// Point d'entrée principal pour l'application Marchand (Web PWA & mobile).
///
/// Démarre exclusivement sur l'espace marchand, initialise les notifications
/// (push Web + natif) et Firebase.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    unawaited(
      NotificationService()
          .init(isMerchantApp: true, navigatorKey: merchantNavigatorKey)
          .catchError((e) {
        if (kDebugMode) debugPrint('NotificationService init erreur: $e');
      }),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase/Notifications non initialisé : $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: MivaFidMerchantApp()));
}

