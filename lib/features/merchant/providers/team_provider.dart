import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../core/api/services/team_service.dart';
import '../models/team_member.dart';

/// `/auth/merchant/team*` est protégé par le guard `merchant` (middleware
/// `admin.only`) : il faut le Dio marchand (`merchantApiClientProvider`), pas
/// le Dio client — sinon le token client se retrouve sur des routes
/// marchandes, ou l'appel part sans token marchand du tout.
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(ref.watch(merchantApiClientProvider));
});

class TeamNotifier extends StateNotifier<AsyncValue<List<TeamMember>>> {
  final TeamService _service;
  TeamNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  /// Erreur brute de la dernière tentative d'[invite]/[toggleActive], `null`
  /// si elle a réussi (ou si aucune n'a encore eu lieu). Exposée telle
  /// quelle — non traduite — pour que l'appelant (l'écran) la fasse passer
  /// par `ErrorTranslator` et affiche le vrai motif (ex. e-mail déjà pris)
  /// plutôt qu'un message générique.
  Object? lastError;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final raw = await _service.list();
      state = AsyncValue.data(raw.map(TeamMember.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> invite({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String role,
  }) async {
    try {
      await _service.invite(name: name, email: email, phone: phone, password: password, role: role);
      lastError = null;
      await refresh();
      return true;
    } catch (e) {
      lastError = e;
      return false;
    }
  }

  Future<bool> toggleActive(int id, bool isActive) async {
    try {
      await _service.toggleActive(id, isActive);
      lastError = null;
      await refresh();
      return true;
    } catch (e) {
      lastError = e;
      return false;
    }
  }
}

// `.autoDispose` : sans lui, l'équipe du premier admin connecté sur cet
// appareil resterait en cache et s'afficherait brièvement à un second admin
// qui se connecte ensuite — le provider doit repartir de zéro à chaque
// (re)montée de l'écran Équipe.
final teamNotifierProvider = StateNotifierProvider.autoDispose<TeamNotifier,
    AsyncValue<List<TeamMember>>>((ref) {
  return TeamNotifier(ref.watch(teamServiceProvider));
});
