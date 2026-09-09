import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../notifications/notification_destination.dart';
import '../router/app_router.dart';
import '../utils/toast_service.dart';

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
    final data = message.data;
    final type = data['type'] as String? ?? '';
    final notificationId = data['notification_id'] as String?;

    const merchantTypes = {
      'merchant_new_client',
      'merchant_low_sms',
      'merchant_weekly_report',
    };
    const warningTypes = {
      'stamp_removed',
      'points_removed',
      'cashback_redeemed',
    };
    const campaignTypes = {
      'campaign',
      'admin_broadcast',
    };

    if (merchantTypes.contains(type)) return;

    if (notificationId != null && ToastService.hasBeenSeen(notificationId)) {
      return;
    }

    final title = notification?.title ?? '';
    final body = notification?.body ?? '';
    if (body.isEmpty && title.isEmpty) return;

    // Cas spéciaux : campagnes marchandes — toast façon vignette Instagram
    if (campaignTypes.contains(type)) {
      final campaignId =
          ((data['campaign_id'] ?? data['id'] ?? notificationId)?.toString() ??
              '')
              .trim();
      final imageUrl = data['image_url'] as String?;
      if (campaignId.isNotEmpty) {
        ToastService.showCampaign(
          title: title.isEmpty ? 'Nouvelle offre' : title,
          body: body.isNotEmpty ? body : title,
          campaignId: campaignId,
          imageUrl: imageUrl,
          notificationId: notificationId,
          notificationData: data,
        );
        return;
      }
    }

    ToastService.markSeen(notificationId);

    final messageText = body.isNotEmpty ? body : title;
    if (warningTypes.contains(type)) {
      ToastService.showWarning(messageText);
    } else {
      ToastService.showSuccess(messageText);
    }
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
