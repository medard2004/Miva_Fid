import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../notifications/notification_destination.dart';
import '../router/app_router.dart';
import '../utils/toast_service.dart';
import 'web_push_interop.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const String webVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;
  bool _isMerchantApp = false;
  GlobalKey<NavigatorState> _navigatorKey = rootNavigatorKey;

  Future<void> init({
    bool isMerchantApp = false,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    _isMerchantApp = isMerchantApp;
    if (navigatorKey != null) {
      _navigatorKey = navigatorKey;
    }

    // Sur mobile natif, on demande la permission dès le boot. Sur le Web/PWA,
    // les navigateurs exigent une action utilisateur (clic) pour afficher
    // la fenêtre d'autorisation — gérée par `WebPushPromptBanner`.
    if (!kIsWeb) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Local notifications setup (uniquement sur plateformes mobiles natives)
    if (!kIsWeb) {
      const androidSettings = AndroidInitializationSettings('@drawable/ic_stat_notification');
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
    }

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

    if (!_isMerchantApp && merchantTypes.contains(type)) return;

    if (notificationId != null && ToastService.hasBeenSeen(notificationId)) {
      return;
    }

    final title = notification?.title ?? data['title']?.toString() ?? '';
    final body = notification?.body ?? data['body']?.toString() ?? '';
    if (body.isEmpty && title.isEmpty) return;

    final restaurantName = data['restaurant_name']?.toString();
    final restaurantLogo = data['restaurant_logo']?.toString();

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
          restaurantName: restaurantName,
          restaurantLogo: restaurantLogo,
          notificationId: notificationId,
          notificationData: data,
        );
        return;
      }
    }

    ToastService.markSeen(notificationId);

    final isWarning = warningTypes.contains(type);
    if ((restaurantName != null && restaurantName.isNotEmpty) ||
        (restaurantLogo != null && restaurantLogo.isNotEmpty)) {
      ToastService.showEstablishmentNotification(
        title: title,
        body: body.isNotEmpty ? body : title,
        restaurantName: restaurantName,
        restaurantLogo: restaurantLogo,
        isWarning: isWarning,
        notificationData: data,
      );
      return;
    }

    final messageText = body.isNotEmpty ? body : title;
    if (isWarning) {
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
    } catch (e) {
      debugPrint('[notification_service] Erreur décodage payload notification: $e');
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
    final context = _navigatorKey.currentContext;
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

  Future<WebPushPermissionState> getWebPermissionState() async {
    if (!kIsWeb) return WebPushPermissionState.unsupported;
    final state = await getWebPushState();
    if (state != WebPushPermissionState.unsupported) {
      return state;
    }
    try {
      final settings = await _messaging.getNotificationSettings();
      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional =>
          WebPushPermissionState.granted,
        AuthorizationStatus.denied => WebPushPermissionState.denied,
        AuthorizationStatus.notDetermined => WebPushPermissionState.promptable,
      };
    } catch (e) {
      debugPrint('[notification_service] Erreur check permission web: $e');
      return WebPushPermissionState.unsupported;
    }
  }

  Future<bool> hasPromptableWebPermission() async {
    final state = await getWebPermissionState();
    return state == WebPushPermissionState.promptable;
  }

  Future<bool> requestPermissionFromUserGesture() async {
    try {
      if (kIsWeb) {
        final result = await requestWebPushPermission();
        if (result == 'granted') {
          await ensureMessagingServiceWorkerReady();
          return true;
        }
        if (result == 'denied') {
          return false;
        }
      }
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted && kIsWeb) {
        await ensureMessagingServiceWorkerReady();
      }
      return granted;
    } catch (e) {
      debugPrint('[notification_service] Erreur requestPermission web: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      await ensureMessagingServiceWorkerReady();
      if (webVapidKey.isEmpty) {
        debugPrint(
          '[notification_service] FIREBASE_VAPID_KEY non défini : le push Web/PWA nécessite --dart-define=FIREBASE_VAPID_KEY=...',
        );
      }
      return _messaging.getToken(
        vapidKey: webVapidKey.isNotEmpty ? webVapidKey : null,
      );
    }
    return _messaging.getToken();
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
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
