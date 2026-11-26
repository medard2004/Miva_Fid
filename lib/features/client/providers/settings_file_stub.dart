import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/web_local_storage.dart';

const _secureStorage = FlutterSecureStorage();
const _webSettingsKey = 'app_settings_json';
const _webLocalSettingsKey = 'mivafid_app_settings_json';
final Map<String, dynamic> _memoryCache = {};

Future<Map<String, dynamic>> readFileStore() async {
  if (_memoryCache.isNotEmpty) return Map.from(_memoryCache);
  try {
    String? raw;
    if (kIsWeb) {
      raw = webStorageGet(_webLocalSettingsKey);
      if (raw == null || raw.isEmpty) {
        try {
          final legacy = await _secureStorage.read(key: _webSettingsKey);
          if (legacy != null && legacy.isNotEmpty) {
            webStorageSet(_webLocalSettingsKey, legacy);
            raw = legacy;
          }
        } catch (_) {}
      }
    } else {
      raw = await _secureStorage.read(key: _webSettingsKey);
    }
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _memoryCache.addAll(decoded);
      return Map.from(_memoryCache);
    }
  } catch (e) {
    debugPrint('[settings_file_stub] Erreur lecture settings web: $e');
  }
  return Map.from(_memoryCache);
}

Future<void> writeFileStore(Map<String, dynamic> data) async {
  _memoryCache
    ..clear()
    ..addAll(data);
  try {
    final encoded = jsonEncode(data);
    if (kIsWeb) {
      webStorageSet(_webLocalSettingsKey, encoded);
      return;
    }
    await _secureStorage.write(key: _webSettingsKey, value: encoded);
  } catch (e) {
    debugPrint('[settings_file_stub] Erreur écriture settings web: $e');
  }
}
