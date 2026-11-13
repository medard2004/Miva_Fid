import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart' as core_colors;
import '../core/theme/app_colors.dart';
import 'settings_file_stub.dart'
    if (dart.library.io) 'settings_file_io.dart';

/// Langues prises en charge par l'app.
const List<Locale> supportedLocales = [Locale('fr'), Locale('en')];

/// Petite persistance locale pour les préférences (thème, langue) :
/// sur mobile un fichier JSON (sans dépendance native superflue),
/// sur web stockage sécurisé / mémoire.
class _SettingsStore {
  static Future<Map<String, dynamic>> read() => readFileStore();

  static Future<void> write(String key, String value) async {
    try {
      final current = await read();
      current[key] = value;
      await writeFileStore(current);
    } catch (e) {
      debugPrint('[settings_provider] Erreur écriture préférence $key: $e');
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
