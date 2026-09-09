import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';

/// Appels HTTP du centre de notifications (`/notifications/*` côté client,
/// `/merchant/notifications/*` côté marchand — même forme des deux côtés,
/// seul [basePath] change).
class NotificationService {
  final ApiClient _apiClient;
  final String _basePath;

  NotificationService(this._apiClient, {String basePath = '/notifications'})
      : _basePath = basePath;

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

  Future<List<Map<String, dynamic>>> list() => _guard(() async {
        final response = await _apiClient.dio.get(_basePath);
        return ((response.data as Map)['data'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      });

  Future<void> markRead(String id) => _guard(() async {
        await _apiClient.dio.post('$_basePath/$id/read');
      });

  Future<void> markAllRead() => _guard(() async {
        await _apiClient.dio.post('$_basePath/read-all');
      });

  Future<void> delete(String id) => _guard(() async {
        await _apiClient.dio.delete('$_basePath/$id');
      });

  Future<void> deleteAll() => _guard(() async {
        await _apiClient.dio.delete(_basePath);
      });
}
