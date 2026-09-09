import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/api/core/api_client.dart';
import 'package:miva_fid/core/api/storage/token_storage.dart';

class _FakeTokenStorage implements TokenStorageBase {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> deleteToken() async {}
}

void main() {
  group('ApiClient', () {
    // Le backend de dev par défaut (`ApiConstants.baseUrl`) est un tunnel
    // ngrok gratuit : sans ce header, ngrok sert sa page d'avertissement
    // HTML à toute requête portant un User-Agent de navigateur — donc
    // systématiquement sur Flutter Web (Chrome) — au lieu de la relayer au
    // backend Laravel. Le client natif (mobile) n'est jamais touché.
    test('envoie ngrok-skip-browser-warning par défaut sur chaque requête', () {
      final client = ApiClient(tokenStorage: _FakeTokenStorage());

      expect(
        client.dio.options.headers['ngrok-skip-browser-warning'],
        'true',
      );
    });
  });
}
