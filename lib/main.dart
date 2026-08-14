import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Le splash natif se ferme automatiquement dès la première frame Flutter
  // peinte (comportement par défaut, fiable) — SplashScreen prend le relais
  // avec son animation dès cet instant.

  // Hive init
  await Hive.initFlutter();
  await Hive.openBox('stamps_queue');
  await Hive.openBox('cards_cache');
  await Hive.openBox('merchant_cache');

  // Supabase init
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://YOUR_PROJECT.supabase.co',
    ),
    publishableKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'YOUR_ANON_KEY',
    ),
  );

  runApp(const ProviderScope(child: MivaFidApp()));
}
