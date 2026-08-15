import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage.dart';

/// Stockage du token marchand, séparé de [TokenStorage] (client) pour que les
/// deux sessions puissent coexister sur le même appareil sans se remplacer.
class MerchantTokenStorage implements TokenStorageBase {
  static const _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'merchant_auth_token';

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
