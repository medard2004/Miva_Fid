import 'web_push_interop_types.dart';

Future<WebPushPermissionState> getWebPushState() async =>
    WebPushPermissionState.unsupported;

Future<String> requestWebPushPermission() async => 'unsupported';

Future<bool> ensureMessagingServiceWorkerReady() async => false;
