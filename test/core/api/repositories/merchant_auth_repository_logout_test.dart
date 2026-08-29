import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/api/core/api_client.dart';
import 'package:miva_fid/core/api/repositories/merchant_auth_repository.dart';
import 'package:miva_fid/core/api/services/merchant_auth_service.dart';
import 'package:miva_fid/core/api/storage/token_storage.dart';

/// N'appelle jamais le réseau : seule la mécanique `suppressUnauthorized`
/// (ApiClient -> AuthInterceptor) doit être exercée par ce test. Mirror de
/// `test/core/api/repositories/auth_repository_test.dart` (client).
class _FakeMerchantAuthService extends MerchantAuthService {
  _FakeMerchantAuthService(ApiClient apiClient) : super(apiClient);

  @override
  Future<void> logout() async {}
}

class _FakeTokenStorage implements TokenStorageBase {
  String? _token = 'existing-token';

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async => _token = null;
}

void main() {
  group('MerchantAuthRepository.logout — garde "session expirée" post-déconnexion', () {
    test(
        'suppressUnauthorized reste actif juste après logout(), le temps '
        "qu'une requête déjà en vol (401 tardif) ne déclenche pas à tort le "
        'toast "session expirée"', () async {
      final tokenStorage = _FakeTokenStorage();
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final authService = _FakeMerchantAuthService(apiClient);
      final repo = MerchantAuthRepository(authService, tokenStorage);

      expect(authService.suppressUnauthorized, false);

      await repo.logout();

      expect(authService.suppressUnauthorized, true);
      expect(await tokenStorage.getToken(), isNull);
    });

    test('suppressUnauthorized se désactive après le délai de grâce', () async {
      final tokenStorage = _FakeTokenStorage();
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final authService = _FakeMerchantAuthService(apiClient);
      final repo = MerchantAuthRepository(authService, tokenStorage);

      await repo.logout();
      expect(authService.suppressUnauthorized, true);

      await Future.delayed(const Duration(seconds: 3));

      expect(authService.suppressUnauthorized, false);
    });
  });
}
