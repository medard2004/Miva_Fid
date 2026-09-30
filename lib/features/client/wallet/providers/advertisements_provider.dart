import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/providers/api_providers.dart';
import '../../../../models/advertisement_model.dart';

final clientAdvertisementsProvider =
    FutureProvider.autoDispose<List<AdvertisementModel>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    final response = await apiClient.dio.get('/client/advertisements');
    final data = response.data;
    if (data is Map<String, dynamic> && data['advertisements'] is List) {
      final list = data['advertisements'] as List;
      return list
          .map((item) =>
              AdvertisementModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  } catch (e) {
    debugPrint('[advertisements_provider] Erreur chargement advertisements: $e');
    return [];
  }
});
