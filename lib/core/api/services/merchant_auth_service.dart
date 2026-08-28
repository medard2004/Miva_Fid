import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';

/// Appels HTTP du flux auth marchand (`/auth/merchant/*`). Mirror de
/// [AuthService] (client), scope limité à l'inscription/connexion.
class MerchantAuthService {
  final ApiClient _apiClient;

  MerchantAuthService(this._apiClient);

  set suppressUnauthorized(bool value) => _apiClient.suppressUnauthorized = value;

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

  Future<Map<String, dynamic>> register(String email, String password) =>
      _guard(() async {
        final response = await _apiClient.dio.post('/auth/merchant/register', data: {
          'email': email,
          'password': password,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> login(String email, String password) =>
      _guard(() async {
        final response = await _apiClient.dio.post('/auth/merchant/login', data: {
          'email': email,
          'password': password,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> staffLogin(String email, String password) =>
      _guard(() async {
        final response = await _apiClient.dio.post('/auth/merchant/staff/login', data: {
          'email': email,
          'password': password,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> socialLogin(
    String provider,
    String idToken, {
    String action = 'login',
  }) =>
      _guard(() async {
        final response = await _apiClient.dio.post('/auth/merchant/social', data: {
          'provider': provider,
          'id_token': idToken,
          'action': action,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateBusinessInfo(Map<String, dynamic> data) =>
      _guard(() async {
        final response =
            await _apiClient.dio.put('/auth/merchant/profile', data: data);
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> uploadLogo(File file) => _guard(() async {
        final formData = FormData.fromMap({
          'logo': await MultipartFile.fromFile(file.path, filename: 'logo.jpg'),
        });
        final response =
            await _apiClient.dio.post('/auth/merchant/profile/logo', data: formData);
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> deleteLogo() => _guard(() async {
        final response =
            await _apiClient.dio.delete('/auth/merchant/profile/logo');
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> verifyPassword(String currentPassword) =>
      _guard(() async {
        final response =
            await _apiClient.dio.post('/auth/merchant/verify-password', data: {
          'current_password': currentPassword,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) =>
      _guard(() async {
        final response =
            await _apiClient.dio.put('/auth/merchant/change-password', data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateNotificationPreferences(
          Map<String, bool> patch) =>
      _guard(() async {
        final response = await _apiClient.dio
            .put('/auth/merchant/notification-preferences', data: patch);
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updatePlan(String planSlug) => _guard(() async {
        final response = await _apiClient.dio
            .put('/auth/merchant/plan', data: {'plan': planSlug});
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateEmail(
    String email,
    String currentPassword,
  ) =>
      _guard(() async {
        final response =
            await _apiClient.dio.put('/auth/merchant/email', data: {
          'email': email,
          'current_password': currentPassword,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<void> deleteAccount(String currentPassword) => _guard(() async {
        await _apiClient.dio.delete('/auth/merchant/account', data: {
          'current_password': currentPassword,
        });
      });

  Future<Map<String, dynamic>> getMe() => _guard(() async {
        final response = await _apiClient.dio.get('/auth/merchant/me');
        return response.data as Map<String, dynamic>;
      });

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/merchant/logout');
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        _throwFromDio(e);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  /// Construit la clé de payload appropriée pour un identifiant (mirror
  /// `AuthService._identifierPayload`, côté client) : `email` si `@`, sinon
  /// `phone`.
  Map<String, String> _identifierPayload(String identifier) {
    if (identifier.contains('@')) {
      return {'email': identifier};
    }
    return {'phone': identifier};
  }

  Future<Map<String, dynamic>> forgotPassword(String identifier) =>
      _guard(() async {
        final response = await _apiClient.dio.post(
          '/auth/merchant/forgot-password',
          data: _identifierPayload(identifier),
        );
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> verifyResetOtp(String identifier, String otp) =>
      _guard(() async {
        final response = await _apiClient.dio.post('/auth/merchant/verify-otp', data: {
          ..._identifierPayload(identifier),
          'otp': otp,
        });
        return response.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> resetPassword(
    String identifier,
    String resetToken,
    String password,
  ) =>
      _guard(() async {
        final response =
            await _apiClient.dio.post('/auth/merchant/reset-password', data: {
          ..._identifierPayload(identifier),
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': password,
        });
        return response.data as Map<String, dynamic>;
      });
}
