import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app_client.dart';
import 'firebase_options.dart';

/// Point d'entrée principal pour l'application Client (Flutter Web).
///
/// Démarre exclusivement sur l'espace client avec support d'accès direct par URL
/// (ex: `/join?code=RESTO123`), sans dépendances natives SQLite ou notifications locales.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Active le routing Web propre (sans '#') pour un deep linking direct par URL
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase Web non initialisé : $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: MivaFidClientApp()));
}

