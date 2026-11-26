import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../storage/web_local_storage.dart';

/// Interface commune à [TokenStorage] (client) et [MerchantTokenStorage],
/// pour que [ApiClient]/[AuthInterceptor] restent agnostiques du rôle.
abstract class TokenStorageBase {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}

class TokenStorage implements TokenStorageBase {
  static const _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _webTokenKey = 'mivafid_auth_token';

  @override
  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      webStorageSet(_webTokenKey, token);
      return;
    }
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    if (kIsWeb) {
      final stored = webStorageGet(_webTokenKey);
      if (stored != null && stored.isNotEmpty) return stored;
      try {
        final legacy = await _secureStorage.read(key: _tokenKey);
        if (legacy != null && legacy.isNotEmpty) {
          webStorageSet(_webTokenKey, legacy);
          return legacy;
        }
      } catch (_) {}
      return null;
    }
    return await _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> deleteToken() async {
    if (kIsWeb) {
      webStorageRemove(_webTokenKey);
      try {
        await _secureStorage.delete(key: _tokenKey);
      } catch (_) {}
      return;
    }
    await _secureStorage.delete(key: _tokenKey);
  }
}
