import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_merchant.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

/// Point d'entrée principal pour l'application Marchand (Android natif).
///
/// Démarre exclusivement sur l'espace marchand, initialise les notifications locales
/// et Firebase natif, et préserve le cache SQLite hors-ligne.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().init();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase/Notifications non initialisé : $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: MivaFidMerchantApp()));
}

