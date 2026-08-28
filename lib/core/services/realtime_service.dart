import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/config/api_constants.dart';
import '../api/core/api_client.dart';

/// Clé publique du serveur Reverb — dérivée de `.env` côté Laravel
/// (`REVERB_APP_KEY`), overridable en dart-define comme `API_BASE_URL` si un
/// déploiement change de valeur. La clé d'app Reverb est publique par
/// conception (c'est le secret côté serveur qui protège).
///
/// Port et TLS sont déduits de `ApiConstants.baseUrl` par défaut (même
/// host/port que l'API) plutôt que fixés en dur : le proxy nginx de dev
/// (`docker/nginx-dev/` côté backend) multiplexe API et Reverb sur le même
/// port 8000, seul port réellement joignable depuis l'app quand elle passe
/// par le tunnel ngrok (le plan gratuit ne tunnelle qu'un seul port — un
/// Reverb exposé séparément sur 8080 y serait tout simplement inatteignable,
/// et les mises à jour de carte cessaient d'arriver en direct). `REVERB_PORT`
/// / `REVERB_TLS` restent overridables en dart-define pour un déploiement où
/// Reverb serait réellement sur un host/port distinct.
class ReverbConfig {
  ReverbConfig._();

  static const int _portOverride = int.fromEnvironment('REVERB_PORT', defaultValue: -1);
  static const String appKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'lmr8oqvyjygvcbcujywu',
  );
  static const bool _hasTlsOverride = bool.hasEnvironment('REVERB_TLS');
  static const bool _tlsOverride = bool.fromEnvironment('REVERB_TLS');

  static int portFor(Uri apiUri) => _portOverride != -1 ? _portOverride : apiUri.port;

  static bool useTlsFor(Uri apiUri) =>
      _hasTlsOverride ? _tlsOverride : apiUri.scheme == 'https';
}

/// Client WebSocket minimal pour le protocole Pusher (celui que parle
/// Laravel Reverb) — aucun package `pusher_channels_flutter` disponible ne
/// supporte un host personnalisé (vérifié : la version publiée la plus
/// récente ne construit `PusherOptions` qu'avec `cluster`, jamais un host
/// self-hosted), donc implémentation directe plutôt qu'une dépendance qui ne
/// couvrirait pas Reverb.
///
/// Périmètre volontairement réduit à ce dont l'app a besoin : un seul canal
/// privé à la fois (client OU marchand, jamais les deux en même temps — un
/// appareil n'est connecté que dans un seul rôle), un seul jeu d'événements
/// écoutés (mise à jour de carte / récompense de fidélité, diffusées par le
/// backend à la fois sur `loyalty.{clientId}` et `merchant.{restaurantId}`,
/// voir `LoyaltyCardUpdated`/`LoyaltyRewardUpdated` côté backend). Pas de
/// canaux publics/présence, pas de reconnexion agressive — une carte qui n'a
/// pas pu être patchée en direct reste simplement à jour au prochain
/// chargement normal de l'écran.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _socketId;
  String? _channelName;
  ApiClient? _apiClient;
  bool _disposed = true;

  final _cardUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rewardUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();

  /// Payload `LoyaltyCardUpdated::broadcastWith()` — id/progress/status/etc.
  Stream<Map<String, dynamic>> get onCardUpdated => _cardUpdatedController.stream;

  /// Payload `LoyaltyRewardUpdated::broadcastWith()` — `{id, status}`, à
  /// chaque déblocage/validation/annulation d'une récompense.
  Stream<Map<String, dynamic>> get onRewardUpdated => _rewardUpdatedController.stream;

  /// Émis à chaque (ré)abonnement réussi au canal privé — y compris le tout
  /// premier après [connect]. Un événement diffusé pendant que le socket
  /// était coupé (app en arrière-plan) n'est jamais rejoué par le serveur :
  /// une reconnexion réussie est le seul signal qu'un consommateur peut
  /// utiliser pour se remettre à jour par un rechargement complet.
  Stream<void> get onReconnected => _reconnectedController.stream;

  /// Ouvre la connexion et s'abonne au canal privé donné — `channelName` est
  /// le nom SANS le préfixe `private-` (ex. `loyalty.42` côté client,
  /// `merchant.7` côté marchand ; voir `routes/channels.php`). Idempotent :
  /// un appel alors qu'une connexion est déjà active la remplace proprement
  /// (ex. changement de compte).
  void connect({required String channelName, required ApiClient apiClient}) {
    disconnect();
    _disposed = false;
    _channelName = channelName;
    _apiClient = apiClient;
    _open();
  }

  void disconnect() {
    _disposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _socketId = null;
  }

  void dispose() {
    disconnect();
    _cardUpdatedController.close();
    _rewardUpdatedController.close();
    _reconnectedController.close();
  }

  void _open() {
    final apiUri = Uri.parse(ApiConstants.baseUrl);
    final scheme = ReverbConfig.useTlsFor(apiUri) ? 'wss' : 'ws';
    final uri = Uri(
      scheme: scheme,
      host: apiUri.host,
      port: ReverbConfig.portFor(apiUri),
      path: '/app/${ReverbConfig.appKey}',
      queryParameters: {'protocol': '7', 'client': 'flutter', 'version': '1.0'},
    );

    try {
      _channel = WebSocketChannel.connect(uri);
    } catch (e) {
      _scheduleReconnect();
      return;
    }

    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), _open);
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic> message;
    try {
      message = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final event = message['event'] as String?;
    switch (event) {
      case 'pusher:connection_established':
        final data = _decodeData(message['data']);
        _socketId = data?['socket_id'] as String?;
        _pingTimer?.cancel();
        _pingTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _send({'event': 'pusher:ping', 'data': {}}),
        );
        _subscribePrivateChannel();
        return;
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': {}});
        return;
      case 'pusher:error':
        if (kDebugMode) debugPrint('RealtimeService: $message');
        return;
      case 'loyalty.card.updated':
        final data = _decodeData(message['data']);
        if (data != null) _cardUpdatedController.add(data);
        return;
      case 'loyalty.reward.updated':
        final data = _decodeData(message['data']);
        if (data != null) _rewardUpdatedController.add(data);
        return;
    }
  }

  Map<String, dynamic>? _decodeData(dynamic data) {
    if (data is String) {
      try {
        return (jsonDecode(data) as Map).cast<String, dynamic>();
      } catch (_) {
        return null;
      }
    }
    if (data is Map) return data.cast<String, dynamic>();
    return null;
  }

  Future<void> _subscribePrivateChannel() async {
    final socketId = _socketId;
    final channelSuffix = _channelName;
    final apiClient = _apiClient;
    if (socketId == null || channelSuffix == null || apiClient == null) return;

    final channelName = 'private-$channelSuffix';
    try {
      final response = await apiClient.dio.post(
        '/broadcasting/auth',
        data: {'socket_id': socketId, 'channel_name': channelName},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final auth = (response.data as Map)['auth'] as String?;
      if (auth == null) return;
      _send({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName, 'auth': auth},
      });
      _reconnectedController.add(null);
    } catch (e) {
      if (kDebugMode) debugPrint('RealtimeService: auth du canal échouée ($e)');
    }
  }
}
