import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers/api_providers.dart';
import '../models/proximity_settings_model.dart';
import 'merchant_auth_provider.dart';

class ProximitySettingsNotifier
    extends StateNotifier<AsyncValue<ProximitySettingsModel>> {
  final Ref _ref;

  ProximitySettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(merchantApiClientProvider);
      final response = await client.dio.get('/merchant/proximity-settings');
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        state = AsyncValue.data(ProximitySettingsModel.fromJson(data));
      } else {
        throw Exception('Format de réponse invalide');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save({
    required bool enabled,
    required int radiusMeters,
    required String title,
    required String message,
  }) async {
    final client = _ref.read(merchantApiClientProvider);

    final payload = {
      'enabled': enabled,
      'radius_m': radiusMeters,
      'title': title,
      'message': message,
    };

    final response = await client.dio.put(
      '/merchant/proximity-settings',
      data: payload,
    );

    if (response.statusCode == 200 && response.data is Map) {
      // Recharger pour avoir le snapshot complet et rafraîchir le profil marchand
      await load();
      await _ref.read(merchantAuthProvider.notifier).refreshFromApi();
    } else {
      throw Exception('Échec de l\'enregistrement des paramètres');
    }
  }
}

final proximitySettingsProvider = StateNotifierProvider<
    ProximitySettingsNotifier, AsyncValue<ProximitySettingsModel>>(
  (ref) => ProximitySettingsNotifier(ref),
);
