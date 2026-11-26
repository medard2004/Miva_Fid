import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/client/providers/device_token_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/toast_service.dart';

/// Bannière affichée sur le Web / PWA lorsque l'autorisation de notifications
/// Push n'a pas encore été accordée. Un clic sur « Activer » déclenche la
/// demande native du navigateur (qui exige un geste utilisateur sur Chrome et
/// Safari iOS) puis enregistre le token FCM auprès du backend.
class WebPushPromptBanner extends ConsumerStatefulWidget {
  const WebPushPromptBanner({super.key});

  @override
  ConsumerState<WebPushPromptBanner> createState() =>
      _WebPushPromptBannerState();
}

class _WebPushPromptBannerState extends ConsumerState<WebPushPromptBanner> {
  bool _visible = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final shouldShow = await NotificationService().hasPromptableWebPermission();
    if (mounted && shouldShow) {
      setState(() => _visible = true);
    }
  }

  Future<void> _activate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final granted =
          await NotificationService().requestPermissionFromUserGesture();
      if (!mounted) return;

      if (granted) {
        final registered =
            await ref.read(deviceTokenProvider).registerCurrentToken();
        if (!mounted) return;
        if (registered) {
          setState(() => _visible = false);
          ToastService.showSuccess('Notifications activées avec succès !');
        } else {
          ToastService.showError(
            "Autorisation accordée, mais l'enregistrement push a échoué (vérifiez FIREBASE_VAPID_KEY ou le mode PWA installée).",
          );
        }
      } else {
        setState(() => _visible = false);
        ToastService.showInfo(
          'Notifications refusées. Vous pouvez les activer dans les réglages du navigateur.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_visible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.bellRing, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Activez les notifications pour recevoir vos alertes et offres en direct.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _busy ? null : _activate,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _busy ? '...' : 'Activer',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _visible = false),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
