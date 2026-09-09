import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../core/services/realtime_service.dart';
import 'merchant_auth_provider.dart';

/// Connexion Reverb liée à la session marchande (canal `merchant.{id}`,
/// diffusé par `LoyaltyCardUpdated`/`LoyaltyRewardUpdated` au même titre que
/// le canal client `loyalty.{id}`) — ouverte dès l'auth marchande restaurée
/// ou complétée, fermée à la déconnexion. Même schéma que `WalletNotifier`
/// côté client (`lib/features/client/providers/wallet_provider.dart`).
///
/// Ne détient aucun état lui-même : les écrans marchand consomment
/// directement les streams de `RealtimeService.instance`
/// (voir `ClientsNotifier`, `client_detail_screen.dart`). Instancié dès
/// qu'un écran regarde `merchantNotifierProvider` (déjà le cas de la quasi
/// totalité des écrans marchand), qui le `watch`.
class MerchantRealtimeConnection {
  MerchantRealtimeConnection(this._ref) {
    _ref.listen<MerchantAuthState>(
      merchantAuthProvider,
      _onAuthChanged,
      fireImmediately: true,
    );
  }

  final Ref _ref;

  void _onAuthChanged(MerchantAuthState? previous, MerchantAuthState next) {
    final restaurantId = next.restaurant?.id;
    if (next.isAuthenticated && restaurantId != null) {
      RealtimeService.instance.connect(
        channelName: 'merchant.$restaurantId',
        apiClient: _ref.read(merchantApiClientProvider),
      );
    } else if (previous?.isAuthenticated == true && !next.isAuthenticated) {
      RealtimeService.instance.disconnect();
    }
  }
}

final merchantRealtimeConnectionProvider = Provider<MerchantRealtimeConnection>(
  (ref) => MerchantRealtimeConnection(ref),
);
