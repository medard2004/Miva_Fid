import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
