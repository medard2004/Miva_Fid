import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../core/api/repositories/merchant_auth_repository.dart';
import '../models/restaurant_account.dart';

class MerchantAuthState {
  final bool isAuthenticated;
  final RestaurantAccount? restaurant;

  /// Dernière erreur remontée par l'API, brute — traduite côté écran.
  final Object? lastError;

  const MerchantAuthState({
    this.isAuthenticated = false,
    this.restaurant,
    this.lastError,
  });

  MerchantAuthState copyWith({
    bool? isAuthenticated,
    RestaurantAccount? restaurant,
    Object? lastError,
    bool clearError = false,
  }) =>
      MerchantAuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        restaurant: restaurant ?? this.restaurant,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}

/// Session marchande, adossée à l'API Laravel via [MerchantAuthRepository].
/// Mirror de `AuthNotifier` (client), scope limité à inscription/connexion.
class MerchantAuthNotifier extends StateNotifier<MerchantAuthState> {
  final MerchantAuthRepository _authRepository;

  MerchantAuthNotifier(this._authRepository) : super(const MerchantAuthState());

  /// Installe une session déjà validée — utilisé par `appStartupProvider`
  /// après un `GET /auth/merchant/me` réussi au démarrage.
  void setAuthenticated(RestaurantAccount restaurant) {
    state = MerchantAuthState(isAuthenticated: true, restaurant: restaurant);
  }

  /// Vide la session locale sans appeler l'API (déclenché par un 401).
  void clearSession() {
    state = const MerchantAuthState();
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant = await _authRepository.register(email, password);
      state = MerchantAuthState(isAuthenticated: true, restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant = await _authRepository.login(email, password);
      state = MerchantAuthState(isAuthenticated: true, restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> staffLogin(String email, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant = await _authRepository.staffLogin(email, password);
      state = MerchantAuthState(isAuthenticated: true, restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  /// Échange un `id_token` Google/Apple contre une session marchande.
  /// `action: 'signup'` autorise la création d'un compte si aucun n'existe.
  Future<bool> socialLogin(
    String provider,
    String idToken, {
    String action = 'login',
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant = await _authRepository.socialLogin(
        provider,
        idToken,
        action: action,
      );
      state = MerchantAuthState(isAuthenticated: true, restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  /// Recharge le compte depuis `GET /auth/merchant/me`.
  ///
  /// Indispensable après une écriture qui ne renvoie pas le restaurant
  /// (création du programme de fidélité) : sans ça `hasLoyaltyProgram` et la
  /// config carte restent sur leur valeur d'avant l'onboarding.
  Future<bool> refreshFromApi() async {
    try {
      final restaurant = await _authRepository.getMe();
      state = MerchantAuthState(isAuthenticated: true, restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  /// Change la formule d'abonnement (`PUT /auth/merchant/plan`).
  Future<bool> updateNotificationPreferences(Map<String, bool> patch) async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant =
          await _authRepository.updateNotificationPreferences(patch);
      state = state.copyWith(restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> updatePlan(String planSlug) async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant = await _authRepository.updatePlan(planSlug);
      state = state.copyWith(restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> updateBusinessInfo(Map<String, dynamic> data) async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant = await _authRepository.updateBusinessInfo(data);
      state = state.copyWith(restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> uploadLogo(File file) async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant = await _authRepository.uploadLogo(file);
      state = state.copyWith(restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> deleteLogo() async {
    state = state.copyWith(clearError: true);
    try {
      final restaurant = await _authRepository.deleteLogo();
      state = state.copyWith(restaurant: restaurant);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  /// Change l'email du commerce et met à jour la session. Lève l'[ApiException]
  /// du serveur (mauvais mot de passe, email déjà pris) pour que l'appelant
  /// puisse afficher le message exact.
  Future<void> updateEmail(String email, String currentPassword) async {
    final restaurant = await _authRepository.updateEmail(email, currentPassword);
    state = state.copyWith(restaurant: restaurant);
  }

  /// Supprime le compte (soft delete serveur) puis purge la session locale.
  /// Le token est révoqué côté serveur : l'appel logout échouera silencieusement.
  Future<void> deleteAccount(String currentPassword) async {
    await _authRepository.deleteAccount(currentPassword);
    await signOut();
  }

  Future<bool> verifyPassword(String currentPassword) async {
    state = state.copyWith(clearError: true);
    try {
      return await _authRepository.verifyPassword(currentPassword);
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.changePassword(currentPassword, newPassword);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> forgotPassword(String identifier) async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.forgotPassword(identifier);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  /// Renvoie le `reset_token` si l'OTP est bon, `null` sinon.
  Future<String?> verifyResetOtp(String identifier, String otp) async {
    state = state.copyWith(clearError: true);
    try {
      return await _authRepository.verifyResetOtp(identifier, otp);
    } catch (e) {
      state = state.copyWith(lastError: e);
      return null;
    }
  }

  Future<bool> resetPassword(
      String identifier, String resetToken, String password) async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.resetPassword(identifier, resetToken, password);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.logout();
    } catch (_) {
      // Token déjà invalide ou réseau indisponible : on nettoie quand même.
    } finally {
      state = const MerchantAuthState();
    }
  }

  void clearError() {
    if (state.lastError != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

final merchantAuthProvider =
    StateNotifierProvider<MerchantAuthNotifier, MerchantAuthState>((ref) {
  return MerchantAuthNotifier(ref.watch(merchantAuthRepositoryProvider));
});

/// `true` pour un compte Restaurant classique ou un membre d'équipe rôle
/// admin ; `false` pour un opérateur — pilote la navigation réduite
/// (`MerchantShell`) et la redirection du router.
final isAdminProvider = Provider<bool>((ref) {
  final restaurant = ref.watch(merchantAuthProvider.select((s) => s.restaurant));
  return restaurant == null || restaurant.staffRole == 'admin';
});
