import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../router/app_router.dart';
import '../notifications/notification_destination.dart';
import '../../features/client/core/theme/app_colors.dart';
import '../../features/client/core/theme/app_radius.dart';
import '../../features/client/core/theme/app_text_styles.dart';
import '../../features/client/widgets/components/app_tap_scale.dart';

enum ToastType { success, error, warning, info }

class _ToastRequest {
  final String message;
  final ToastType type;
  final Duration duration;
  final String? title;
  final String? imageUrl;
  final String? campaignId;
  final VoidCallback? onTap;

  _ToastRequest({
    required this.message,
    required this.type,
    required this.duration,
    this.title,
    this.imageUrl,
    this.campaignId,
    this.onTap,
  });

  bool get isCampaign => campaignId != null && campaignId!.isNotEmpty;
}

class ToastService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static bool _isShowing = false;
  static final List<_ToastRequest> _queue = [];
  static final Set<String> _recentlyShown = {};
  static const _dedupWindow = Duration(seconds: 10);

  static bool markSeen(String? notificationId) {
    if (notificationId == null || notificationId.isEmpty) return false;
    if (_recentlyShown.contains(notificationId)) return true;
    _recentlyShown.add(notificationId);
    Future.delayed(_dedupWindow, () => _recentlyShown.remove(notificationId));
    return false;
  }

  static bool hasBeenSeen(String? notificationId) {
    if (notificationId == null || notificationId.isEmpty) return false;
    return _recentlyShown.contains(notificationId);
  }

  static void hideCurrent() {
    if (_isShowing && _overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
    _timer?.cancel();
    _timer = null;

    messengerKey.currentState?.hideCurrentSnackBar();

    _processNext();
  }

  static void _processNext() {
    if (_isShowing || _queue.isEmpty) return;
    final next = _queue.removeAt(0);
    _showNow(
      message: next.message,
      type: next.type,
      duration: next.duration,
      title: next.title,
      imageUrl: next.imageUrl,
      campaignId: next.campaignId,
      onTap: next.onTap,
    );
  }

  static void show({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (_isShowing) {
      _queue.add(_ToastRequest(message: message, type: type, duration: duration));
      return;
    }

    _showNow(message: message, type: type, duration: duration);
  }

  /// Affiche un toast façon "carte promo" avec vignette, titre, extrait
  /// et clic ouvrant la page correspondant au type de campagne.
  /// Utilisé pour les notifications de type `campaign` / `admin_broadcast`.
  static void showCampaign({
    required String title,
    required String body,
    required String campaignId,
    String? imageUrl,
    String? notificationId,
    Map<String, dynamic>? notificationData,
    Duration duration = const Duration(seconds: 6),
  }) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    if (notificationId != null && markSeen(notificationId)) return;

    final onTap = () {
      hideCurrent();
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      final destination = resolveNotificationDestination(
        type: notificationData?['type'] as String? ?? 'campaign',
        data: notificationData ?? {
          'campaign_id': campaignId,
          'image_url': imageUrl,
        },
        title: title,
        body: body,
      );
      navigateToNotificationDestination(ctx, destination);
    };

    final request = _ToastRequest(
      message: body,
      type: ToastType.info,
      duration: duration,
      title: title,
      imageUrl: imageUrl,
      campaignId: campaignId,
      onTap: onTap,
    );

    if (_isShowing) {
      _queue.add(request);
      return;
    }

    _showNow(
      message: request.message,
      type: request.type,
      duration: request.duration,
      title: request.title,
      imageUrl: request.imageUrl,
      campaignId: request.campaignId,
      onTap: request.onTap,
    );
  }

  static void _showNow({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
    String? title,
    String? imageUrl,
    String? campaignId,
    VoidCallback? onTap,
  }) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final isCampaign = campaignId != null && campaignId.isNotEmpty;

    late Widget toast;
    if (isCampaign) {
      toast = _CampaignToastWidget(
        title: title ?? message,
        body: message,
        imageUrl: imageUrl,
        onDismiss: hideCurrent,
        onTap: onTap ?? hideCurrent,
      );
    } else {
      final Color backgroundColor;
      final Color accentColor;
      final IconData iconData;

      switch (type) {
        case ToastType.success:
          backgroundColor = AppColors.successTint;
          accentColor = AppColors.success;
          iconData = Icons.check_circle_rounded;
          break;
        case ToastType.error:
          backgroundColor = AppColors.errorTint;
          accentColor = AppColors.error;
          iconData = Icons.error_rounded;
          break;
        case ToastType.warning:
          backgroundColor = AppColors.warningTint;
          accentColor = AppColors.warning;
          iconData = Icons.warning_rounded;
          break;
        case ToastType.info:
          backgroundColor = AppColors.primaryTint;
          accentColor = AppColors.primary;
          iconData = Icons.info_rounded;
          break;
      }

      toast = _ToastWidget(
        message: message,
        backgroundColor: backgroundColor,
        accentColor: accentColor,
        iconData: iconData,
        onDismiss: hideCurrent,
      );
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 12,
        right: 12,
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: toast,
          ),
        ),
      ),
    );

    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay != null) {
      overlay.insert(_overlayEntry!);
      _isShowing = true;
      _timer = Timer(duration, hideCurrent);
    }
  }

  static void showSuccess(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(message: message, type: ToastType.success, duration: duration);
  }

  static void showError(String message,
      {Duration duration = const Duration(seconds: 4)}) {
    show(message: message, type: ToastType.error, duration: duration);
  }

  static void showWarning(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(message: message, type: ToastType.warning, duration: duration);
  }

  static void showInfo(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(message: message, type: ToastType.info, duration: duration);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast standard (texte + icône)
// ─────────────────────────────────────────────────────────────────────────────

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color accentColor;
  final IconData iconData;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.accentColor,
    required this.iconData,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.iconData, color: widget.accentColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    widget.message,
                    style: AppTextStyles.bodyMedium(
                            color: widget.accentColor)
                        .copyWith(
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.close_rounded,
                    color: widget.accentColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast "campagne promo" façon vignette Instagram
// ─────────────────────────────────────────────────────────────────────────────

class _CampaignToastWidget extends StatefulWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _CampaignToastWidget({
    required this.title,
    required this.body,
    required this.onDismiss,
    required this.onTap,
    this.imageUrl,
  });

  @override
  State<_CampaignToastWidget> createState() => _CampaignToastWidgetState();
}

class _CampaignToastWidgetState extends State<_CampaignToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.8),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.topCenter,
          child: AppTapScale(
            scaleDown: 0.985,
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vignette image 1:1 façon Insta
                    Container(
                      width: 92,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                      ),
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.surfaceMuted,
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceMuted,
                                child: Icon(
                                  LucideIcons.imageOff,
                                  color: AppColors.inkMuted(opacity: 0.4),
                                  size: 22,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.9),
                                    AppColors.liningPlum,
                                  ],
                                ),
                              ),
                              child: Icon(
                                LucideIcons.megaphone,
                                color: Colors.white.withValues(alpha: 0.92),
                                size: 30,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 11, 6, 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Nouvelle offre',
                                    style: AppTextStyles.eyebrow(
                                      color: AppColors.primary,
                                    ).copyWith(letterSpacing: 0.6),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: widget.onDismiss,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 6, left: 4, top: 2, bottom: 2),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.inkMuted(opacity: 0.45),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium(
                                color: AppColors.ink,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall(
                                color: AppColors.inkMuted(opacity: 0.72),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Taper pour voir',
                                  style: AppTextStyles.bodySmall(
                                    color: AppColors.primary,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
