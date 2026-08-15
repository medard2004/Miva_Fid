import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';

/// Appels HTTP du programme de fidélité marchand (`/loyalty-programs`).
class LoyaltyProgramService {
  final ApiClient _apiClient;

  LoyaltyProgramService(this._apiClient);

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

  Future<Map<String, dynamic>> save(Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.dio.post('/loyalty-programs', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _throwFromDio(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }
}
