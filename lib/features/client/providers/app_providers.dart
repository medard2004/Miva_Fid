import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miva_fid/core/api/providers/api_providers.dart';
import 'package:miva_fid/core/api/repositories/auth_repository.dart';
import 'package:miva_fid/features/client/data/mock_data.dart';
import 'package:miva_fid/features/client/models/reward.dart';
import 'package:miva_fid/features/client/models/app_notification.dart';
import 'package:miva_fid/features/client/models/user.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Récompenses
// ─────────────────────────────────────────────────────────────────────────────

class RewardsNotifier extends StateNotifier<List<Reward>> {
  RewardsNotifier() : super(MockData.rewards);

  List<Reward> get active =>
      state.where((r) => r.status == RewardStatus.active).toList();
  List<Reward> get locked =>
      state.where((r) => r.status == RewardStatus.locked).toList();
  List<Reward> get used =>
      state.where((r) => r.status == RewardStatus.used).toList();

  List<Reward> forCard(String cardId) =>
      state.where((r) => r.cardId == cardId).toList();

  /// Marque une récompense active comme utilisée.
  void redeem(String id) {
    state = [
      for (final r in state)
        if (r.id == id && r.status == RewardStatus.active)
          Reward(
            id: r.id,
            cardId: r.cardId,
            restaurantName: r.restaurantName,
            title: r.title,
            description: r.description,
            status: RewardStatus.used,
            usedAt: DateTime.now(),
          )
        else
          r,
    ];
  }
}

final rewardsProvider = StateNotifierProvider<RewardsNotifier, List<Reward>>(
  (ref) => RewardsNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(MockData.notifications);

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Préférences de notification par établissement
// ─────────────────────────────────────────────────────────────────────────────

/// Activation des notifications par carte (par défaut activées).
class NotificationPrefsNotifier extends StateNotifier<Map<String, bool>> {
  NotificationPrefsNotifier() : super(const {});

  bool isEnabled(String cardId) => state[cardId] ?? true;

  void toggle(String cardId, bool enabled) {
    state = {...state, cardId: enabled};
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, Map<String, bool>>(
  (ref) => NotificationPrefsNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Données en cours de saisie pendant l'inscription (flow temporaire)
// ─────────────────────────────────────────────────────────────────────────────

/// Données collectées en cours d'inscription, portées entre les écrans.
class SignupFlowData {
  final String fullName;
  final int? age;
  final String phone;
  final AuthProvider provider;
  final DateTime? birthDate;

  const SignupFlowData({
    this.fullName = '',
    this.age,
    this.phone = '',
    this.provider = AuthProvider.phone,
    this.birthDate,
  });

  SignupFlowData copyWith({
    String? fullName,
    int? age,
    String? phone,
    AuthProvider? provider,
    DateTime? birthDate,
  }) =>
      SignupFlowData(
        fullName: fullName ?? this.fullName,
        age: age ?? this.age,
        phone: phone ?? this.phone,
        provider: provider ?? this.provider,
        birthDate: birthDate ?? this.birthDate,
      );
}

class SignupFlowNotifier extends StateNotifier<SignupFlowData> {
  SignupFlowNotifier() : super(const SignupFlowData());

  void startPhoneSignup({
    required String fullName,
    required String phone,
    DateTime? birthDate,
    int? age,
  }) {
    final calculatedAge = age ??
        (birthDate != null
            ? (DateTime.now().difference(birthDate).inDays ~/ 365)
            : null);
    state = SignupFlowData(
      fullName: fullName,
      age: calculatedAge,
      phone: phone,
      birthDate: birthDate,
      provider: AuthProvider.phone,
    );
  }

  void startSocialSignup({required AuthProvider provider}) {
    state = SignupFlowData(provider: provider);
  }

  void setSocialDetails({
    required String fullName,
    required String phone,
    DateTime? birthDate,
  }) {
    state = state.copyWith(
      fullName: fullName,
      phone: phone,
      birthDate: birthDate,
    );
  }

  void reset() => state = const SignupFlowData();
}

final signupFlowProvider =
    StateNotifierProvider<SignupFlowNotifier, SignupFlowData>(
  (ref) => SignupFlowNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Utilisateur / Auth
// ─────────────────────────────────────────────────────────────────────────────


class AuthState {
  final bool isAuthenticated;
  final AppUser? user;

  /// Dernière erreur remontée par l'API, brute.
  ///
  /// Volontairement non traduite ici : c'est [ErrorTranslator], côté écran,
  /// qui décide si elle s'affiche sous un champ ou dans un toast.
  final Object? lastError;

  /// Avatar choisi localement, affiché en attendant que l'upload aboutisse.
  final File? localAvatar;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.lastError,
    this.localAvatar,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    AppUser? user,
    Object? lastError,
    bool clearError = false,
    File? localAvatar,
    bool clearLocalAvatar = false,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        lastError: clearError ? null : (lastError ?? this.lastError),
        localAvatar: clearLocalAvatar ? null : (localAvatar ?? this.localAvatar),
      );
}

/// Session client, adossée à l'API Laravel via [AuthRepository].
///
/// Convention de retour : les méthodes renvoient un booléen de succès et
/// déposent l'erreur dans `state.lastError` plutôt que de la propager. Les
/// écrans lisent `lastError` et le passent à [ErrorTranslator], ce qui évite
/// un `try/catch` dans chaque formulaire. Les exceptions ne sont relancées
/// que là où l'appelant doit réagir (avatar, mise à jour de profil).
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState());

  // ── Session ───────────────────────────────────────────────────────────────

  /// Installe une session déjà validée — utilisé par `appStartupProvider`
  /// après un `GET /auth/me` réussi au démarrage.
  void setAuthenticated(AppUser user) {
    state = AuthState(isAuthenticated: true, user: user);
  }

  /// Vide la session locale sans appeler l'API.
  ///
  /// Déclenché par [AuthInterceptor] sur un 401 : le token est déjà rejeté
  /// par le serveur, un `POST /auth/logout` échouerait de la même façon.
  void clearSession() {
    state = const AuthState();
  }

  // ── Connexion par téléphone ───────────────────────────────────────────────

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _authRepository.login(phone, password);
      state = AuthState(isAuthenticated: true, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  // ── Inscription ───────────────────────────────────────────────────────────

  /// Pré-valide l'étape 1 (nom, téléphone, date de naissance) avant d'afficher
  /// l'écran mot de passe.
  ///
  /// Le serveur y fait tourner `FraudRiskService` et l'unicité du numéro :
  /// mieux vaut échouer ici que de faire saisir un mot de passe pour rien.
  Future<bool> validateRegisterStep1(SignupFlowData flow) async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.validateRegisterStep1({
        'first_name': flow.fullName,
        'phone': flow.phone,
        if (flow.birthDate != null) 'birthdate': _asDate(flow.birthDate!),
      });
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  Future<bool> register(SignupFlowData flow, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _authRepository.register({
        'first_name': flow.fullName,
        'phone': flow.phone,
        'password': password,
        'password_confirmation': password,
        if (flow.birthDate != null) 'birthdate': _asDate(flow.birthDate!),
      });
      state = AuthState(isAuthenticated: true, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  // ── Réinitialisation du mot de passe ──────────────────────────────────────

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
      String identifier, String token, String password) async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.resetPassword(identifier, token, password);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  // ── Connexion sociale ─────────────────────────────────────────────────────

  /// Échange un `id_token` Google/Apple contre une session.
  ///
  /// `needs_profile_completion` vaut `true` quand le fournisseur n'a pas donné
  /// de numéro de téléphone : l'écran de complétion doit alors s'intercaler
  /// avant le wallet.
  Future<({bool success, bool needsProfileCompletion})> socialLogin(
    AuthProvider provider,
    String idToken, {
    String action = 'login',
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final providerName =
          provider == AuthProvider.google ? 'google' : 'apple';
      final response = await _authRepository.socialLogin(
        providerName,
        idToken,
        action: action,
      );

      state = AuthState(
        isAuthenticated: true,
        user: response['client'] as AppUser,
      );

      return (
        success: true,
        needsProfileCompletion:
            response['needs_profile_completion'] as bool? ?? false,
      );
    } catch (e) {
      state = state.copyWith(lastError: e);
      return (success: false, needsProfileCompletion: false);
    }
  }

  // ── Complétion du profil ──────────────────────────────────────────────────

  /// Complète le profil après une inscription par téléphone
  /// (ville, quartier, e-mail).
  Future<bool> completeProfile({
    String? city,
    String? country,
    String? neighborhood,
    String? email,
  }) async {
    if (state.user == null) return false;
    state = state.copyWith(clearError: true);
    try {
      final user = await _authRepository.updateProfile({
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (email != null) 'email': email,
      });
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  /// Complète le profil après une connexion sociale
  /// (nom, téléphone, date de naissance).
  Future<bool> completeSocialProfile({
    required String fullName,
    required String phone,
    DateTime? birthDate,
    String? city,
    String? country,
    String? neighborhood,
    String? email,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _authRepository.completeSocialProfile({
        'first_name': fullName,
        'phone': phone,
        if (birthDate != null) 'birthdate': _asDate(birthDate),
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (email != null) 'email': email,
      });
      state = AuthState(isAuthenticated: true, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(lastError: e);
      return false;
    }
  }

  // ── Mot de passe (session ouverte) ────────────────────────────────────────

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

  // ── Profil ────────────────────────────────────────────────────────────────

  /// Met à jour le profil, en optimiste puis en corrigeant avec la réponse
  /// serveur. En cas d'échec l'état précédent est restauré : afficher des
  /// données non persistées induirait l'utilisateur en erreur.
  Future<void> updateFullProfile({
    String? fullName,
    String? phoneNumber,
    DateTime? birthDate,
    String? email,
    String? city,
    String? country,
    String? neighborhood,
  }) async {
    if (state.user == null) return;

    final previousUser = state.user!;

    state = state.copyWith(
      user: previousUser.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        birthDate: birthDate,
        email: email,
        city: city,
        country: country,
        neighborhood: neighborhood,
        profileCompleted: true,
      ),
    );

    try {
      final data = <String, dynamic>{};

      // L'API stocke prénom et nom séparément.
      if (fullName != null) {
        final parts = fullName.trim().split(RegExp(r'\s+'));
        data['first_name'] = parts.first;
        data['last_name'] = parts.skip(1).join(' ');
      }
      if (phoneNumber != null) data['phone'] = phoneNumber;
      if (email != null) data['email'] = email;
      if (city != null) data['city'] = city;
      if (country != null) data['country'] = country;
      if (neighborhood != null) data['neighborhood'] = neighborhood;
      if (birthDate != null) data['birthdate'] = _asDate(birthDate);

      if (data.isNotEmpty) {
        state = state.copyWith(user: await _authRepository.updateProfile(data));
      }
    } catch (e) {
      state = state.copyWith(user: previousUser, lastError: e);
      rethrow;
    }
  }

  /// Affiche immédiatement le fichier choisi, puis le remplace par l'URL
  /// renvoyée par le serveur une fois l'upload terminé.
  Future<void> updateAvatar(File file) async {
    if (state.user == null) return;
    state = state.copyWith(localAvatar: file);
    try {
      state = state.copyWith(user: await _authRepository.uploadAvatar(file));
    } catch (e) {
      state = state.copyWith(clearLocalAvatar: true, lastError: e);
      rethrow;
    }
  }

  Future<void> removeAvatar() async {
    if (state.user == null) return;
    state = state.copyWith(clearLocalAvatar: true);
    state = state.copyWith(user: await _authRepository.deleteAvatar());
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.logout();
    } catch (_) {
      // Un échec réseau ou un token déjà invalide ne doit pas empêcher la
      // déconnexion : le token local est purgé dans tous les cas.
    } finally {
      state = const AuthState();
    }
  }

  void clearError() {
    if (state.lastError != null) {
      state = state.copyWith(clearError: true);
    }
  }

  /// Formate une date au format attendu par Laravel (`Y-m-d`).
  static String _asDate(DateTime date) =>
      date.toIso8601String().split('T').first;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
