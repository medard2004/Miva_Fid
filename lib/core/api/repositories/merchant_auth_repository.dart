import 'dart:async';
import 'dart:io';

import '../services/merchant_auth_service.dart';
import '../storage/token_storage.dart' show TokenStorageBase;
import '../core/api_exceptions.dart';
import '../../cache/offline_cache_service.dart';
import '../../../features/merchant/models/restaurant_account.dart';

/// Normalise la charge `restaurant` de la réponse `staffLogin`.
///
/// Contrairement à `login`/`getMe`, la réponse réelle de `staffLogin` porte
/// `actor` en frère de `restaurant` (racine de la réponse), pas imbriqué
/// dedans — un correctif backend parallèle vise à harmoniser ça, mais rien
/// ne garantit qu'il ait atterri, ni sous quelle forme : on gère donc les
/// deux formes (imbriquée ou sœur), en préférant `restaurant.actor` s'il est
/// déjà présent.
///
/// Exposée (top-level, pas privée) pour être testée directement sans appel
/// HTTP réel — voir `test/core/api/repositories/merchant_auth_repository_test.dart`.
Map<String, dynamic> mergeStaffLoginActor(Map<String, dynamic> response) {
  final restaurant =
      Map<String, dynamic>.from(response['restaurant'] as Map? ?? {});
  if (response['actor'] != null && restaurant['actor'] == null) {
    restaurant['actor'] = response['actor'];
  }
  return restaurant;
}

class MerchantAuthRepository {
  final MerchantAuthService _authService;
  final TokenStorageBase _tokenStorage;
  final OfflineCacheService? _cache;

  MerchantAuthRepository(this._authService, this._tokenStorage, [this._cache]);

  Future<RestaurantAccount> register(String email, String password) async {
    final response = await _authService.register(email, password);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<RestaurantAccount> login(String email, String password) async {
    final response = await _authService.login(email, password);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<RestaurantAccount> staffLogin(String email, String password) async {
    final response = await _authService.staffLogin(email, password);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    final merged = mergeStaffLoginActor(response);
    await _cache?.saveMerchantAccount(merged);
    return RestaurantAccount.fromJson(merged);
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
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<RestaurantAccount> updateBusinessInfo(Map<String, dynamic> data) async {
    final response = await _authService.updateBusinessInfo(data);
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<RestaurantAccount> uploadLogo(File file) async {
    final response = await _authService.uploadLogo(file);
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<RestaurantAccount> deleteLogo() async {
    final response = await _authService.deleteLogo();
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<RestaurantAccount> updateEmail(
    String email,
    String currentPassword,
  ) async {
    final response = await _authService.updateEmail(email, currentPassword);
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<void> deleteAccount(String currentPassword) =>
      _authService.deleteAccount(currentPassword);

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

  Future<RestaurantAccount> updateNotificationPreferences(
      Map<String, bool> patch) async {
    final response = await _authService.updateNotificationPreferences(patch);
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<RestaurantAccount> updatePlan(String planSlug) async {
    final response = await _authService.updatePlan(planSlug);
    final restaurantData = response['restaurant'] ?? {};
    if (restaurantData is Map<String, dynamic>) {
      await _cache?.saveMerchantAccount(restaurantData);
    }
    return RestaurantAccount.fromJson(restaurantData);
  }

  Future<RestaurantAccount> getMe() async {
    try {
      final response = await _authService.getMe();
      final restaurantData = response['restaurant'] ?? {};
      if (restaurantData is Map<String, dynamic>) {
        await _cache?.saveMerchantAccount(restaurantData);
      }
      return RestaurantAccount.fromJson(restaurantData);
    } catch (e) {
      if (e is! UnauthorizedException && _cache != null) {
        final cached = await _cache.getMerchantAccount();
        if (cached != null) {
          return RestaurantAccount.fromJson(cached);
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
      await _cache?.clearMerchantData();
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
}
