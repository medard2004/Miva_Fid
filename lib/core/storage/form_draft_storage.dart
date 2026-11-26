import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistance légère des brouillons de formulaires multi-étapes (onboarding
/// marchand, création de campagne, etc.) afin de survivre à un rechargement
/// navigateur (`F5` / Reload) sur le Web comme à un redémarrage sur mobile.
class FormDraftStorage {
  FormDraftStorage._();

  static const _storage = FlutterSecureStorage();
  static const String _prefix = 'form_draft_';

  static Future<void> saveJson(String key, Map<String, dynamic> data) async {
    try {
      await _storage.write(
        key: '$_prefix$key',
        value: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('[FormDraftStorage] Erreur sauvegarde $key: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadJson(String key) async {
    try {
      final raw = await _storage.read(key: '$_prefix$key');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('[FormDraftStorage] Erreur lecture $key: $e');
    }
    return null;
  }

  static Future<void> clear(String key) async {
    try {
      await _storage.delete(key: '$_prefix$key');
    } catch (e) {
      debugPrint('[FormDraftStorage] Erreur suppression $key: $e');
    }
  }
}
