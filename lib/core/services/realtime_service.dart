import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/config/api_constants.dart';
import '../api/core/api_client.dart';

/// Port/clé publique du serveur Reverb — dérivés de `.env` côté Laravel
/// (`REVERB_PORT`, `REVERB_APP_KEY`), overridables en dart-define comme
/// `API_BASE_URL` si un déploiement change de valeurs. La clé d'app Reverb
/// est publique par conception (c'est le secret côté serveur qui protège).
class ReverbConfig {
  ReverbConfig._();

  static const int port = int.fromEnvironment('REVERB_PORT', defaultValue: 8080);
  static const String appKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'lmr8oqvyjygvcbcujywu',
  );
  static const bool useTls = bool.fromEnvironment('REVERB_TLS', defaultValue: false);
}

/// Client WebSocket minimal pour le protocole Pusher (celui que parle
/// Laravel Reverb) — aucun package `pusher_channels_flutter` disponible ne
/// supporte un host personnalisé (vérifié : la version publiée la plus
/// récente ne construit `PusherOptions` qu'avec `cluster`, jamais un host
/// self-hosted), donc implémentation directe plutôt qu'une dépendance qui ne
/// couvrirait pas Reverb.
///
/// Périmètre volontairement réduit à ce dont l'app a besoin : un canal privé
/// par client, un seul type d'événement écouté (mise à jour de carte de
/// fidélité). Pas de canaux publics/présence, pas de reconnexion agressive —
/// une carte qui n'a pas pu être patchée en direct reste simplement à jour
/// au prochain chargement normal du wallet.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _socketId;
  String? _clientId;
  ApiClient? _apiClient;
  bool _disposed = true;

  final _cardUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  /// Payload `LoyaltyCardUpdated::broadcastWith()` — id/progress/status/etc.
  Stream<Map<String, dynamic>> get onCardUpdated => _cardUpdatedController.stream;

  /// Ouvre la connexion et s'abonne au canal privé du client authentifié.
  /// Idempotent : un appel alors qu'une connexion est déjà active la
  /// remplace proprement (ex. changement de compte).
  void connect({required String clientId, required ApiClient apiClient}) {
    disconnect();
    _disposed = false;
    _clientId = clientId;
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
  }

  void _open() {
    final host = Uri.parse(ApiConstants.baseUrl).host;
    const scheme = ReverbConfig.useTls ? 'wss' : 'ws';
    final uri = Uri(
      scheme: scheme,
      host: host,
      port: ReverbConfig.port,
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
    final clientId = _clientId;
    final apiClient = _apiClient;
    if (socketId == null || clientId == null || apiClient == null) return;

    final channelName = 'private-loyalty.$clientId';
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
    } catch (e) {
      if (kDebugMode) debugPrint('RealtimeService: auth du canal échouée ($e)');
    }
  }
}
