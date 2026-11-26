import 'dart:js_interop';

import 'web_push_interop_types.dart';

@JS('window.__mivaWebPush')
external _MivaWebPushJs? get _mivaWebPush;

extension type _MivaWebPushJs(JSObject _) implements JSObject {
  external JSString getState();
  external JSPromise<JSBoolean> ensureServiceWorker();
  external JSPromise<JSString> requestPermission();
}

Future<WebPushPermissionState> getWebPushState() async {
  final bridge = _mivaWebPush;
  if (bridge == null) return WebPushPermissionState.unsupported;
  try {
    final raw = bridge.getState().toDart;
    return switch (raw) {
      'granted' => WebPushPermissionState.granted,
      'default' => WebPushPermissionState.promptable,
      'denied' => WebPushPermissionState.denied,
      'ios_install_required' => WebPushPermissionState.iosInstallRequired,
      _ => WebPushPermissionState.unsupported,
    };
  } catch (_) {
    return WebPushPermissionState.unsupported;
  }
}

Future<String> requestWebPushPermission() async {
  final bridge = _mivaWebPush;
  if (bridge == null) return 'unsupported';
  try {
    final result = await bridge.requestPermission().toDart;
    return result.toDart;
  } catch (_) {
    return 'denied';
  }
}

Future<bool> ensureMessagingServiceWorkerReady() async {
  final bridge = _mivaWebPush;
  if (bridge == null) return false;
  try {
    final ready = await bridge.ensureServiceWorker().toDart;
    return ready.toDart;
  } catch (_) {
    return false;
  }
}
