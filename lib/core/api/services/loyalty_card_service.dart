import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';

/// Appels HTTP des cartes de fidélité client (`/loyalty-cards/*`).
class LoyaltyCardService {
  final ApiClient _apiClient;

  LoyaltyCardService(this._apiClient);

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
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
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

  Future<List<Map<String, dynamic>>> listMine() => _guard(() async {
        final response = await _apiClient.dio.get('/loyalty-cards');
        return ((response.data as Map)['cards'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      });

  Future<Map<String, dynamic>> joinByQrToken(String qrToken) => _guard(() async {
        final response = await _apiClient.dio.post('/loyalty-cards/join', data: {
          'qr_token': qrToken,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getCard(String id) => _guard(() async {
        final response = await _apiClient.dio.get('/loyalty-cards/$id');
        return response.data as Map<String, dynamic>;
      });
}
