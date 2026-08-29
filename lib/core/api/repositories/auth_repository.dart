import 'dart:async';
import 'dart:io';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';
import '../../../features/client/models/user.dart';

class AuthRepository {
  final AuthService _authService;
  final TokenStorageBase _tokenStorage;

  AuthRepository(this._authService, this._tokenStorage);

  Future<AppUser> login(String phone, String password) async {
    final response = await _authService.login(phone, password);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    return AppUser.fromJson(response['client'] ?? {});
  }

  Future<AppUser> register(Map<String, dynamic> data) async {
    final response = await _authService.register(data);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    return AppUser.fromJson(response['client'] ?? {});
  }

  Future<Map<String, dynamic>> socialLogin(String provider, String idToken,
      {String action = 'login'}) async {
    final response =
        await _authService.socialLogin(provider, idToken, action: action);
    final token = response['access_token'];
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }
    return {
      'client': AppUser.fromJson(response['client'] ?? {}),
      'needs_profile_completion': response['needs_profile_completion'] ?? false,
    };
  }

  Future<AppUser> completeSocialProfile(Map<String, dynamic> data) async {
    final response = await _authService.completeSocialProfile(data);
    // The backend might return a new token or just the updated client
    return AppUser.fromJson(response['client'] ?? {});
  }

  Future<bool> validateRegisterStep1(Map<String, dynamic> data) async {
    await _authService.validateRegisterStep1(data);
    return true;
  }

  Future<AppUser> getMe() async {
    final response = await _authService.getMe();
    return AppUser.fromJson(response['client'] ?? {});
  }

  Future<void> logout() async {
    _authService.suppressUnauthorized = true;
    try {
      if (await isLoggedIn()) {
        await _authService.logout();
      }
    } finally {
      await _tokenStorage.deleteToken();
      // Ne pas réactiver tout de suite : une requête déjà en vol au moment
      // de la déconnexion (rafraîchissement wallet, heartbeat realtime...)
      // peut recevoir son 401 quelques centaines de ms après que ce
      // `logout()` a lui-même abouti — sans ce délai, `suppressUnauthorized`
      // redevient `false` juste avant l'arrivée de ce 401 tardif, qui
      // déclenche alors à tort le toast "session expirée" en pleine
      // déconnexion volontaire. `unawaited` : ne fait pas attendre l'appelant
      // (navigation vers l'écran de connexion immédiate).
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
    return AppUser.fromJson(response['client'] ?? {});
  }

  Future<AppUser> uploadAvatar(File file) async {
    final response = await _authService.uploadAvatar(file);
    return AppUser.fromJson(response['client'] ?? {});
  }

  Future<AppUser> deleteAvatar() async {
    final response = await _authService.deleteAvatar();
    return AppUser.fromJson(response['client'] ?? {});
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
