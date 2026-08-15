import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Supabase : encore utilisé par le module marchand et son parcours
  // d'inscription. Le module client, lui, passe désormais par l'API Laravel
  // (voir lib/core/api/). À retirer quand les endpoints marchand existeront.
    await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://YOUR_PROJECT.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'YOUR_ANON_KEY',
    ),
  );

  runApp(const ProviderScope(child: MivaFidApp()));
}
