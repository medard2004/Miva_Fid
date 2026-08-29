import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../notifications/notification_destination.dart';
import '../router/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      // Notif locale affichée pendant que l'app est au premier plan (voir
      // `_handleForegroundMessage`) — tapée, elle doit rediriger comme
      // n'importe quel autre push.
      onDidReceiveNotificationResponse: (response) {
        _routeFromPayload(response.payload);
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App en arrière-plan, ramenée au premier plan par un tap sur le push.
    FirebaseMessaging.onMessageOpenedApp.listen(_routeForMessage);

    // App tuée, relancée par un tap sur le push (seul point d'entrée pour ce
    // cas côté `firebase_messaging` — pas d'équivalent `onMessageOpenedApp`).
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _routeForMessage(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'mivafid_channel',
      'Miva-Fid',
      channelDescription: 'Notifications Miva-Fid',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      // Le payload doit porter tout ce dont le résolveur de destination a
      // besoin — `data` seul ne contient pas le titre/texte (utile pour la
      // destination "campagne", qui affiche le texte de la notif elle-même).
      payload: jsonEncode({
        ...message.data,
        'title': notification.title ?? '',
        'body': notification.body ?? '',
      }),
    );
  }

  void _routeFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final merged = (jsonDecode(payload) as Map).cast<String, dynamic>();
      _route(data: merged, title: merged['title'] as String? ?? '', body: merged['body'] as String? ?? '');
    } catch (_) {
      // Payload malformé (ancienne version de l'app, format inattendu) :
      // pas de redirection plutôt qu'un crash.
    }
  }

  void _routeForMessage(RemoteMessage message) {
    _route(
      data: message.data,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
    );
  }

  /// Destination ouverte au clic sur un push — voir
  /// `resolveNotificationDestination`, seule source de vérité pour la
  /// politique de navigation (partagée avec le tap dans la boîte in-app).
  void _route({required Map<String, dynamic> data, required String title, required String body}) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'] as String? ?? '';
    final destination = resolveNotificationDestination(
      type: type,
      data: data,
      title: title,
      body: body,
    );
    navigateToNotificationDestination(context, destination);
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mivafid_channel',
      'Miva-Fid',
      channelDescription: 'Notifications Miva-Fid',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
