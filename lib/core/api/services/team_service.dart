import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';

/// Appels HTTP de la gestion d'équipe marchande (`/auth/merchant/team*`,
/// Task 7). Réservé aux comptes `admin` côté backend (middleware
/// `admin.only`) ; mirror de [MerchantAuthService] pour la gestion d'erreurs,
/// sans dépendance croisée entre services.
class TeamService {
  final ApiClient _apiClient;

  TeamService(this._apiClient);

  Never _throwFromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (status == 422 || status == 429) {
      throw ValidationException.fromResponse(data, statusCode: status);
    }

    if (status == 401) {
      throw UnauthorizedException(_backendMessage(data) ?? 'unauthorized');
    }

    if (status != null) {
      throw ServerException(
        _backendMessage(data) ?? e.message ?? 'server error',
        statusCode: status,
      );
    }

    throw NetworkException(e.message ?? 'network error');
  }

  String? _backendMessage(dynamic data) {
    if (data is Map && data['message'] != null)
      return data['message'].toString();
    return null;
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      _throwFromDio(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> list() => _guard(() async {
        final response = await _apiClient.dio.get('/auth/merchant/team');
        return List<Map<String, dynamic>>.from(response.data['team'] as List);
      });

  Future<void> invite({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String role,
  }) =>
      _guard(() async {
        await _apiClient.dio.post('/auth/merchant/team', data: {
          'name': name,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'password': password,
          'role': role,
        });
      });

  Future<void> update(int id, Map<String, dynamic> data) => _guard(() async {
        await _apiClient.dio.put('/auth/merchant/team/$id', data: data);
      });

  Future<void> toggleActive(int id, bool isActive) => _guard(() async {
        await _apiClient.dio.patch('/auth/merchant/team/$id/toggle-active', data: {
          'is_active': isActive,
        });
      });
}
