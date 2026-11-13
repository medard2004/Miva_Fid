import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secureStorage = FlutterSecureStorage();
const _webSettingsKey = 'app_settings_json';
final Map<String, dynamic> _memoryCache = {};

Future<Map<String, dynamic>> readFileStore() async {
  if (_memoryCache.isNotEmpty) return Map.from(_memoryCache);
  try {
    final raw = await _secureStorage.read(key: _webSettingsKey);
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
    await _secureStorage.write(key: _webSettingsKey, value: jsonEncode(data));
  } catch (e) {
    debugPrint('[settings_file_stub] Erreur écriture settings web: $e');
  }
}

