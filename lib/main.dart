import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Le splash natif se ferme automatiquement dès la première frame Flutter
  // peinte (comportement par défaut, fiable) — SplashScreen prend le relais
  // avec son animation dès cet instant.

  // Firebase : requis par les notifications push et par la connexion Google,
  // dont le backend valide l'`id_token` comme un jeton Firebase.
  //
  // L'initialisation est tolérante à l'échec : tant que `flutterfire
  // configure` n'a pas été lancé, il n'y a pas de `firebase_options.dart` ni
  // de `google-services.json`, et faire planter le démarrage empêcherait de
  // travailler sur tout le reste de l'app.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().init();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase non initialisé : $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: MivaFidApp()));
}
