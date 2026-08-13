import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart' as core_colors;
import '../core/theme/app_colors.dart';

/// Langues prises en charge par l'app.
const List<Locale> supportedLocales = [Locale('fr'), Locale('en')];

/// Petite persistance locale pour les préférences (thème, langue) — un
/// fichier JSON plutôt qu'un plugin dédié (shared_preferences), pour ne
/// pas ajouter de dépendance native supplémentaire à l'app.
class _SettingsStore {
  static const _fileName = 'settings.json';
  static File? _cachedFile;

  static Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    _cachedFile = File('${dir.path}/$_fileName');
    return _cachedFile!;
  }

  static Future<Map<String, dynamic>> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> write(String key, String value) async {
    try {
      final file = await _file();
      final current = await read();
      current[key] = value;
      await file.writeAsString(jsonEncode(current));
    } catch (_) {
      // Persistance best-effort : une écriture échouée ne doit jamais
      // bloquer le changement de préférence en mémoire.
    }
  }
}

const _themeModeKey = 'themeMode';
const _localeKey = 'locale';

// ─────────────────────────────────────────────────────────────────────────────
// Thème clair / sombre / système
// ─────────────────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await _SettingsStore.read();
    state = switch (prefs[_themeModeKey]) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _SettingsStore.write(_themeModeKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Luminosité imposée par le système, tenue à jour en direct.
///
/// On passe par un [WidgetsBindingObserver] plutôt que par
/// `PlatformDispatcher.onPlatformBrightnessChanged` : ce callback n'a
/// qu'un seul emplacement, déjà occupé par Flutter lui-même, et l'écraser
/// casserait la mise à jour de `MediaQuery`.
class PlatformBrightnessNotifier extends StateNotifier<Brightness>
    with WidgetsBindingObserver {
  PlatformBrightnessNotifier()
    : super(WidgetsBinding.instance.platformDispatcher.platformBrightness) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    state = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final platformBrightnessProvider =
    StateNotifierProvider<PlatformBrightnessNotifier, Brightness>(
      (ref) => PlatformBrightnessNotifier(),
    );

/// Luminosité effective de l'app : le mode choisi, résolu contre la
/// luminosité système quand le mode vaut [ThemeMode.system].
///
/// C'est ce provider — et non [themeModeProvider] — que doivent observer
/// les écrans du module client : ils peignent leurs couleurs via les
/// tokens statiques d'`AppColors`, invisibles pour le mécanisme de
/// dépendance de Flutter, donc leur seul déclencheur de reconstruction est
/// cette valeur. Observer [themeModeProvider] ne les réveillait que sur un
/// changement manuel, jamais sur une bascule clair/sombre du système.
///
/// La synchronisation des deux palettes statiques de l'app — celle du
/// module client et celle partagée par l'onboarding et le module
/// commerçant — est faite ici, à la source, pour garantir que les tokens
/// soient déjà à jour quel que soit l'ordre de reconstruction des widgets
/// abonnés.
final appBrightnessProvider = Provider<Brightness>((ref) {
  final mode = ref.watch(themeModeProvider);
  final platformBrightness = ref.watch(platformBrightnessProvider);
  final brightness = switch (mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => platformBrightness,
  };
  AppColors.setBrightness(brightness);
  core_colors.AppColors.setBrightness(brightness);
  return brightness;
});

// ─────────────────────────────────────────────────────────────────────────────
// Langue de l'application
// ─────────────────────────────────────────────────────────────────────────────

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await _SettingsStore.read();
    final saved = prefs[_localeKey] as String?;
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _SettingsStore.write(_localeKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
