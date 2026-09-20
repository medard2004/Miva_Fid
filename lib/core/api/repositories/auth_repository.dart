import 'dart:async';
import 'dart:io';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';
import '../core/api_exceptions.dart';
import '../../cache/offline_cache_service.dart';
import '../../../features/client/models/user.dart';

class AuthRepository {
  final AuthService _authService;
  final TokenStorageBase _tokenStorage;
  final OfflineCacheService? _cache;

  AuthRepository(this._authService, this._tokenStorage, [this._cache]);

  Future<AppUser> login(String phone, String password) async {
    final response = await _authService.login(phone, password);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    final clientData = response['client'] ?? {};
    if (clientData is Map<String, dynamic>) {
      await _cache?.saveClientUser(clientData);
    }
    return AppUser.fromJson(clientData);
  }

  Future<AppUser> register(Map<String, dynamic> data) async {
    final response = await _authService.register(data);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    final clientData = response['client'] ?? {};
    if (clientData is Map<String, dynamic>) {
      await _cache?.saveClientUser(clientData);
    }
    return AppUser.fromJson(clientData);
  }

  Future<Map<String, dynamic>> socialLogin(String provider, String idToken,
      {String action = 'login'}) async {
    final response =
        await _authService.socialLogin(provider, idToken, action: action);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    final clientData = response['client'] ?? {};
    if (clientData is Map<String, dynamic>) {
      await _cache?.saveClientUser(clientData);
    }
    return {
      'client': AppUser.fromJson(clientData),
      'needs_profile_completion': response['needs_profile_completion'] ?? false,
    };
  }

  Future<AppUser> completeSocialProfile(Map<String, dynamic> data) async {
    final response = await _authService.completeSocialProfile(data);
    final clientData = response['client'] ?? {};
    if (clientData is Map<String, dynamic>) {
      await _cache?.saveClientUser(clientData);
    }
    return AppUser.fromJson(clientData);
  }

  Future<bool> validateRegisterStep1(Map<String, dynamic> data) async {
    await _authService.validateRegisterStep1(data);
    return true;
  }

  Future<AppUser> getMe() async {
    try {
      final response = await _authService.getMe();
      final clientData = response['client'] ?? {};
      if (clientData is Map<String, dynamic>) {
        await _cache?.saveClientUser(clientData);
      }
      return AppUser.fromJson(clientData);
    } catch (e) {
      if (e is! UnauthorizedException && _cache != null) {
        final cached = await _cache.getClientUser();
        if (cached != null) {
          return AppUser.fromJson(cached);
        }
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    _authService.suppressUnauthorized = true;
    try {
      if (await isLoggedIn()) {
        await _authService.logout();
      }
    } finally {
      await _tokenStorage.deleteToken();
      await _cache?.clearClientData();
      unawaited(Future.delayed(const Duration(seconds: 2), () {
        _authService.suppressUnauthorized = false;
      }));
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getToken();
    return token != null;
  }

  Future<String> forgotPassword(String identifier) async {
    final response = await _authService.forgotPassword(identifier);
    return response['message'] ?? 'Code envoyé';
  }

  Future<String> verifyResetOtp(String identifier, String otp) async {
    final response = await _authService.verifyResetOtp(identifier, otp);
    return response['reset_token'] as String;
  }

  Future<String> resetPassword(
      String identifier, String resetToken, String password) async {
    final response =
        await _authService.resetPassword(identifier, resetToken, password);
    return response['message'] ?? 'Mot de passe réinitialisé';
  }

  Future<AppUser> updateProfile(Map<String, dynamic> data) async {
    final response = await _authService.updateProfile(data);
    final clientData = response['client'] ?? {};
    if (clientData is Map<String, dynamic>) {
      await _cache?.saveClientUser(clientData);
    }
    return AppUser.fromJson(clientData);
  }

  Future<AppUser> uploadAvatar(File file) async {
    final response = await _authService.uploadAvatar(file);
    final clientData = response['client'] ?? {};
    if (clientData is Map<String, dynamic>) {
      await _cache?.saveClientUser(clientData);
    }
    return AppUser.fromJson(clientData);
  }

  Future<AppUser> deleteAvatar() async {
    final response = await _authService.deleteAvatar();
    final clientData = response['client'] ?? {};
    if (clientData is Map<String, dynamic>) {
      await _cache?.saveClientUser(clientData);
    }
    return AppUser.fromJson(clientData);
  }

  Future<bool> verifyPassword(String currentPassword) async {
    final response = await _authService.verifyPassword(currentPassword);
    return response['valid'] == true;
  }

  Future<String> changePassword(
      String currentPassword, String newPassword) async {
    final response =
        await _authService.changePassword(currentPassword, newPassword);
    return response['message'] ?? 'Mot de passe modifié';
  }
}
