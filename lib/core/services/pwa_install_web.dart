import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Future<bool> promptPwaInstallImpl() async {
  try {
    final fn = globalContext.getProperty('promptPWAInstall'.toJS);
    if (fn != null && fn.typeofEquals('function')) {
      final promise =
          (fn as JSFunction).callAsFunction(globalContext) as JSPromise;
      final res = await promise.toDart;
      return (res as JSBoolean?)?.toDart ?? false;
    }
  } catch (_) {}
  return false;
}

bool canPromptPwaInstallImpl() {
  try {
    final prompt = globalContext.getProperty('deferredPWAInstallPrompt'.toJS);
    return prompt != null && !prompt.isUndefinedOrNull;
  } catch (_) {
    return false;
  }
}

bool isPwaInstalledImpl() {
  try {
    final fn = globalContext.getProperty('isPWAInstalled'.toJS);
    if (fn != null && fn.typeofEquals('function')) {
      final res = (fn as JSFunction).callAsFunction(globalContext);
      return (res as JSBoolean?)?.toDart ?? false;
    }
  } catch (_) {}
  return false;
}

void removeWebSplashImpl() {
  try {
    final fn = globalContext.getProperty('removeSplashFromWeb'.toJS);
    if (fn != null && fn.typeofEquals('function')) {
      (fn as JSFunction).callAsFunction(globalContext);
    }
  } catch (_) {}
}
