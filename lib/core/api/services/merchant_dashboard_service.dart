import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';

/// Appels HTTP du dashboard marchand (`/merchant/*`) : clientèle, validation
/// de tampons, statistiques et campagnes SMS.
///
/// Remplace les requêtes Supabase du module marchand, restées en place après
/// la migration de l'authentification vers Laravel : elles interrogeaient un
/// projet où plus aucune donnée n'était écrite.
class MerchantDashboardService {
  final ApiClient _apiClient;

  MerchantDashboardService(this._apiClient);

  Never _throwFromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (status == 422 || status == 429) {
      throw ValidationException.fromResponse(data, statusCode: status);
    }
    if (status == 401) {
      throw UnauthorizedException(_backendMessage(data) ?? 'unauthorized');
    }
    if (status != null) {
      throw ServerException(
        _backendMessage(data) ?? e.message ?? 'server error',
        statusCode: status,
      );
    }
    throw NetworkException(e.message ?? 'network error');
  }

  String? _backendMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return null;
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      _throwFromDio(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> stats() => _guard(() async {
        final response = await _apiClient.dio.get('/merchant/stats');
        return (response.data as Map).cast<String, dynamic>();
      });

  Future<List<Map<String, dynamic>>> clients({
    String? search,
    String? filter,
  }) =>
      _guard(() async {
        final response = await _apiClient.dio.get(
          '/merchant/clients',
          queryParameters: {
            if (search != null && search.isNotEmpty) 'q': search,
            if (filter != null && filter.isNotEmpty) 'filter': filter,
          },
        );
        return ((response.data as Map)['clients'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      });

  /// Fiche d'une carte du commerce (`GET /merchant/clients/{card}`).
  Future<Map<String, dynamic>?> client(String cardId) async {
    try {
      final response = await _apiClient.dio.get('/merchant/clients/$cardId');
      return ((response.data as Map)['client'] as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _throwFromDio(e);
    }
  }

  /// Historique des opérations d'une carte (`GET /merchant/clients/{card}/history`),
  /// avec attribution : `staff_name`/`staff_role` valent `null` quand
  /// l'opération a été effectuée par l'admin directement (pas par un
  /// opérateur).
  Future<List<Map<String, dynamic>>> history(String cardId) => _guard(() async {
        final response = await _apiClient.dio.get('/merchant/clients/$cardId/history');
        return ((response.data as Map)['history'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      });

  /// Retourne `null` quand aucune carte du commerce ne correspond (404),
  /// l'écran de validation traitant ce cas comme « client inconnu » et non
  /// comme une erreur réseau.
  Future<Map<String, dynamic>?> lookup(String code) async {
    try {
      final response = await _apiClient.dio.get(
        '/merchant/clients/lookup',
        queryParameters: {'code': code},
      );
      return ((response.data as Map)['client'] as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _throwFromDio(e);
    }
  }

  /// [amountFcfa] requis côté serveur en mode "Achat" (`spend`) — le montant
  /// réel de l'achat, converti en points au taux du programme.
  Future<Map<String, dynamic>> addStamp(String cardId, {double? amountFcfa}) =>
      _guard(() async {
        final response = await _apiClient.dio.post(
          '/merchant/clients/$cardId/stamps',
          data: amountFcfa != null ? {'amount_fcfa': amountFcfa} : null,
        );
        return (response.data as Map).cast<String, dynamic>();
      });

  /// Mode Cashback : utilise une partie du solde comme réduction sur
  /// l'achat en cours (`amountFcfa`), plafonnée côté serveur.
  Future<Map<String, dynamic>> redeemCashback(
    String cardId, {
    required double amountFcfa,
    required double redeemAmountFcfa,
  }) =>
      _guard(() async {
        final response = await _apiClient.dio.post(
          '/merchant/clients/$cardId/redeem-cashback',
          data: {
            'amount_fcfa': amountFcfa,
            'redeem_amount_fcfa': redeemAmountFcfa,
          },
        );
        return (response.data as Map).cast<String, dynamic>();
      });

  /// Retourne `null` quand aucune récompense du commerce ne correspond au
  /// jeton scanné (404) — même convention que [lookup].
  Future<Map<String, dynamic>?> lookupReward(String token) async {
    try {
      final response = await _apiClient.dio.get(
        '/merchant/rewards/lookup',
        queryParameters: {'token': token},
      );
      return ((response.data as Map)['reward'] as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _throwFromDio(e);
    }
  }

  Future<Map<String, dynamic>> redeemReward(String rewardId) => _guard(() async {
        final response =
            await _apiClient.dio.post('/merchant/rewards/$rewardId/redeem');
        return (response.data as Map).cast<String, dynamic>();
      });

  Future<Map<String, dynamic>> cancelReward(String rewardId, {String? reason}) =>
      _guard(() async {
        final response = await _apiClient.dio.post(
          '/merchant/rewards/$rewardId/cancel',
          data: reason != null ? {'reason': reason} : null,
        );
        return (response.data as Map).cast<String, dynamic>();
      });

  Future<List<Map<String, dynamic>>> campaigns() => _guard(() async {
        final response = await _apiClient.dio.get('/merchant/campaigns');
        return ((response.data as Map)['campaigns'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      });

  Future<int> recipientCount(String recipientType) => _guard(() async {
        final response = await _apiClient.dio.get(
          '/merchant/campaigns/recipients',
          queryParameters: {'recipient_type': recipientType},
        );
        return (response.data as Map)['recipients_count'] as int? ?? 0;
      });

  Future<void> sendCampaign({
    required String message,
    required String recipientType,
    DateTime? scheduledAt,
  }) =>
      _guard(() async {
        await _apiClient.dio.post('/merchant/campaigns', data: {
          'message': message,
          'recipient_type': recipientType,
          if (scheduledAt != null)
            'scheduled_at': scheduledAt.toIso8601String(),
        });
      });
}
