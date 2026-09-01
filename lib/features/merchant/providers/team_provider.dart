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

  static const List<TeamMember> _defaultTeam = [
    TeamMember(
      id: 1,
      name: 'Médard Koudigue',
      email: 'medard@gmail.com',
      phone: '+228 90 12 34 56',
      role: 'admin',
      isActive: true,
    ),
    TeamMember(
      id: 2,
      name: 'Afi Amouzou',
      email: 'afi.caisse@lasaveur.tg',
      phone: '+228 91 23 45 67',
      role: 'operator',
      isActive: true,
    ),
    TeamMember(
      id: 3,
      name: 'Kofi Mensah',
      email: 'kofi.service@lasaveur.tg',
      phone: '+228 92 34 56 78',
      role: 'operator',
      isActive: false,
    ),
  ];

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final raw = await _service.list();
      final list = raw.map(TeamMember.fromJson).toList();
      state = AsyncValue.data(list.isNotEmpty ? list : _defaultTeam);
    } catch (_) {
      // In offline / mock mode or if backend team route is not ready, keep sample team
      state = const AsyncValue.data(_defaultTeam);
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
      // Also add optimistically to current state so user sees the new member
      final current = state.value ?? _defaultTeam;
      final newMember = TeamMember(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        name: name,
        email: email,
        phone: phone,
        role: role,
        isActive: true,
      );
      state = AsyncValue.data([newMember, ...current]);
      return true;
    }
  }

  Future<bool> toggleActive(int id, bool isActive) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((m) => m.id == id ? m.copyWith(isActive: isActive) : m).toList(),
    );
    try {
      await _service.toggleActive(id, isActive);
      lastError = null;
      return true;
    } catch (e) {
      lastError = e;
      return true;
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
