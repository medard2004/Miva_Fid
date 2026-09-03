import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miva_fid/core/api/providers/api_providers.dart';
import 'package:miva_fid/core/services/realtime_service.dart';
import 'package:miva_fid/features/client/models/referral.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';

/// Parrainages réels du client (pending + validated) — `GET /referrals`.
/// Remplace l'ancien système de partage mocké : chaque carte porte son
/// propre QR/identifiant de parrainage (voir `LoyaltyCard.referralCode`),
/// cet état ne fait que lister ce que le client a déjà obtenu comme
/// parrainages en attente/validés.
class ReferralNotifier extends StateNotifier<List<Referral>> {
  ReferralNotifier(this._ref) : super(const []) {
    _ref.listen<AuthState>(authProvider, _onAuthChanged, fireImmediately: true);
    _realtimeNotifSub = RealtimeService.instance.onNotificationCreated.listen((_) {
      _loadMineWithRetry();
    });
    _realtimeRewardSub = RealtimeService.instance.onRewardUpdated.listen((_) {
      _loadMineWithRetry();
    });
    _reconnectSub = RealtimeService.instance.onReconnected.listen((_) {
      _loadMineWithRetry();
    });
  }

  final Ref _ref;
  StreamSubscription<void>? _realtimeNotifSub;
  StreamSubscription<void>? _realtimeRewardSub;
  StreamSubscription<void>? _reconnectSub;

  void _onAuthChanged(AuthState? previous, AuthState next) {
    if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
      _loadMineWithRetry();
    } else if (previous?.isAuthenticated == true && !next.isAuthenticated) {
      state = const [];
    }
  }

  List<Referral> get pending =>
      state.where((r) => r.status == ReferralStatus.pending).toList();
  List<Referral> get validated =>
      state.where((r) => r.status == ReferralStatus.validated).toList();

  Future<void> loadMine() async {
    state = await _ref.read(referralRepositoryProvider).listMine();
  }

  Future<void> _loadMineWithRetry() async {
    const delays = [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 5)];
    for (var attempt = 0; ; attempt++) {
      try {
        await loadMine();
        return;
      } catch (_) {
        if (attempt >= delays.length) return;
        await Future.delayed(delays[attempt]);
      }
    }
  }

  @override
  void dispose() {
    _realtimeNotifSub?.cancel();
    _realtimeRewardSub?.cancel();
    _reconnectSub?.cancel();
    super.dispose();
  }
}

final referralProvider = StateNotifierProvider<ReferralNotifier, List<Referral>>(
  (ref) => ReferralNotifier(ref),
);

