import 'pwa_install_stub.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart';

class PwaInstallService {
  PwaInstallService._();

  static bool canPromptInstall() => canPromptPwaInstallImpl();

  static bool isInstalled() => isPwaInstalledImpl();

  static Future<bool> promptInstall() => promptPwaInstallImpl();

  static void removeWebSplash() => removeWebSplashImpl();
}
