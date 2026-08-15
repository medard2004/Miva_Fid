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

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.forgotPassword(email);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  /// Renvoie le `reset_token` si l'OTP est bon, `null` sinon.
  Future<String?> verifyResetOtp(String email, String otp) async {
    state = state.copyWith(clearError: true);
    try {
      return await _authRepository.verifyResetOtp(email, otp);
    } catch (e) {
      state = state.copyWith(lastError: e);
      return null;
    }
  }

  Future<bool> resetPassword(
      String email, String resetToken, String password) async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.resetPassword(email, resetToken, password);
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
