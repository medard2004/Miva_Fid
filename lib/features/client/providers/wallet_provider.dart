import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miva_fid/core/api/providers/api_providers.dart';
import 'package:miva_fid/core/api/repositories/loyalty_card_repository.dart'
    show JoinCardResult;
import 'package:miva_fid/core/services/realtime_service.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';

class WalletNotifier extends StateNotifier<List<LoyaltyCard>> {
  WalletNotifier(this._ref) : super(const []) {
    // Connexion Reverb liée à la session client : ouverte dès l'auth
    // restaurée/complétée, fermée à la déconnexion. `fireImmediately` couvre
    // le cas d'une session déjà active au moment où ce notifier est créé.
    _ref.listen<AuthState>(authProvider, _onAuthChanged, fireImmediately: true);
    _realtimeSub = RealtimeService.instance.onCardUpdated.listen(applyRealtimeUpdate);
  }

  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  void _onAuthChanged(AuthState? previous, AuthState next) {
    final backendId = next.user?.backendId;
    if (next.isAuthenticated && backendId != null) {
      RealtimeService.instance.connect(
        clientId: backendId.toString(),
        apiClient: _ref.read(apiClientProvider),
      );
      // Fetch cards automatically when authenticated (e.g. after login or
      // startup). `previous == null` covers the `fireImmediately` case: the
      // notifier is often first created *after* login already happened
      // (wallet screen is the first widget to watch `walletProvider`), so
      // the initial listener call already sees an authenticated state with
      // no prior state to compare against — without this branch, that case
      // was silently skipped and the wallet stayed empty until a manual
      // pull-to-refresh.
      if (previous == null || !previous.isAuthenticated) {
        loadMine().catchError((_) {});
      }
    } else if (previous?.isAuthenticated == true && !next.isAuthenticated) {
      RealtimeService.instance.disconnect();
      state = const []; // Clear cards on logout
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    RealtimeService.instance.disconnect();
    super.dispose();
  }

  /// Recharge le wallet depuis `GET /loyalty-cards` — appelé par
  /// `appStartupProvider` juste après restauration de la session, avant que
  /// l'écran de démarrage ne route vers le wallet. Sans ce rechargement, les
  /// cartes rejointes lors d'une session précédente n'existaient que dans cet
  /// état en mémoire et disparaissaient à chaque relance de l'app, alors
  /// qu'elles étaient bien enregistrées côté serveur.
  Future<void> loadMine() async {
    state = await _ref.read(loyaltyCardRepositoryProvider).listMine();
  }

  LoyaltyCard? byId(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Ajoute une carte après un scan QR (onboarding).
  void joinRestaurant(LoyaltyCard card) {
    state = [card, ...state];
  }

  /// Rejoint le programme de fidélité d'un restaurant à partir de son
  /// `qr_token` (scan réel ou saisie manuelle) — crée/retrouve une vraie
  /// carte côté backend et l'ajoute au wallet.
  Future<JoinCardResult> joinByQrToken(String qrToken) async {
    final result = await _ref
        .read(loyaltyCardRepositoryProvider)
        .joinByQrToken(qrToken);
    if (state.any((c) => c.id == result.card.id)) return result;
    state = [result.card, ...state];
    return result;
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex >= state.length) return;
    if (oldIndex == newIndex) return;
    final list = List<LoyaltyCard>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  void addStamp(String cardId) {
    state = [
      for (final c in state)
        if (c.id == cardId && c.mechanic == LoyaltyMechanic.stamps)
          c.copyWith(stampsCurrent: (c.stampsCurrent + 1).clamp(0, c.stampsGoal))
        else
          c,
    ];
  }

  /// Patch une carte depuis un événement Reverb (`RealtimeService.onCardUpdated`)
  /// — met à jour la progression sans recharger tout le wallet. Ignoré si la
  /// carte ne fait pas (encore) partie de l'état local (ex. reçu avant le
  /// premier `loadMine()`).
  void applyRealtimeUpdate(Map<String, dynamic> payload) {
    final id = payload['id']?.toString();
    if (id == null) return;
    state = [
      for (final c in state)
        if (c.id == id) c.applyRealtimeUpdate(payload) else c,
    ];
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, List<LoyaltyCard>>(
  (ref) => WalletNotifier(ref),
);

final selectedCardProvider = StateProvider<String?>((ref) => null);
