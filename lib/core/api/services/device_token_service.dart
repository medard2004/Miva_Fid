import 'dart:developer' as developer;

import '../core/api_client.dart';

/// Enregistre le token FCM de l'appareil côté backend (`POST /device-tokens`).
///
/// Best-effort : un échec réseau ici ne doit jamais bloquer le flux
/// d'authentification, donc toute erreur est avalée après journalisation.
class DeviceTokenService {
  final ApiClient _apiClient;

  DeviceTokenService(this._apiClient);

  Future<void> register(String token, String platform) async {
    try {
      await _apiClient.dio.post('/device-tokens', data: {
        'token': token,
        'platform': platform,
      });
    } catch (e) {
      developer.log('DeviceTokenService: échec enregistrement token', error: e);
    }
  }
}
