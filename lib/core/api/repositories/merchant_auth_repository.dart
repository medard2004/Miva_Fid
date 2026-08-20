import 'dart:io';

import '../services/merchant_auth_service.dart';
import '../storage/merchant_token_storage.dart';
import '../../../features/merchant/models/restaurant_account.dart';

class MerchantAuthRepository {
  final MerchantAuthService _authService;
  final MerchantTokenStorage _tokenStorage;

  MerchantAuthRepository(this._authService, this._tokenStorage);

  Future<RestaurantAccount> register(String email, String password) async {
    final response = await _authService.register(email, password);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    return RestaurantAccount.fromJson(response['restaurant'] ?? {});
  }

  Future<RestaurantAccount> login(String email, String password) async {
    final response = await _authService.login(email, password);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    return RestaurantAccount.fromJson(response['restaurant'] ?? {});
  }

  Future<RestaurantAccount> socialLogin(
    String provider,
    String idToken, {
    String action = 'login',
  }) async {
    final response =
        await _authService.socialLogin(provider, idToken, action: action);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    return RestaurantAccount.fromJson(response['restaurant'] ?? {});
  }

  Future<RestaurantAccount> updateBusinessInfo(Map<String, dynamic> data) async {
    final response = await _authService.updateBusinessInfo(data);
    return RestaurantAccount.fromJson(response['restaurant'] ?? {});
  }

  Future<RestaurantAccount> uploadLogo(File file) async {
    final response = await _authService.uploadLogo(file);
    return RestaurantAccount.fromJson(response['restaurant'] ?? {});
  }

  Future<RestaurantAccount> deleteLogo() async {
    final response = await _authService.deleteLogo();
    return RestaurantAccount.fromJson(response['restaurant'] ?? {});
  }

  Future<RestaurantAccount> updatePlan(String planSlug) async {
    final response = await _authService.updatePlan(planSlug);
    return RestaurantAccount.fromJson(response['restaurant'] ?? {});
  }

  Future<RestaurantAccount> getMe() async {
    final response = await _authService.getMe();
    return RestaurantAccount.fromJson(response['restaurant'] ?? {});
  }

  Future<void> logout() async {
    _authService.suppressUnauthorized = true;
    try {
      if (await isLoggedIn()) {
        await _authService.logout();
      }
    } finally {
      await _tokenStorage.deleteToken();
      _authService.suppressUnauthorized = false;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getToken();
    return token != null;
  }

  Future<String> forgotPassword(String email) async {
    final response = await _authService.forgotPassword(email);
    return response['message'] ?? 'Code envoyé';
  }

  Future<String> verifyResetOtp(String email, String otp) async {
    final response = await _authService.verifyResetOtp(email, otp);
    return response['reset_token'] as String;
  }

  Future<String> resetPassword(
      String email, String resetToken, String password) async {
    final response =
        await _authService.resetPassword(email, resetToken, password);
    return response['message'] ?? 'Mot de passe réinitialisé';
  }
}
