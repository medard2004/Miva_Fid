import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../router/app_router.dart';
import '../notifications/notification_destination.dart';
import '../theme/app_colors.dart';
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

    void onTap() {
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
    }

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
          iconData = LucideIcons.check;
          break;
        case ToastType.error:
          backgroundColor = AppColors.dangerTint;
          accentColor = AppColors.danger;
          iconData = LucideIcons.circleAlert;
          break;
        case ToastType.warning:
          backgroundColor = AppColors.warningTint;
          accentColor = AppColors.warning;
          iconData = LucideIcons.triangleAlert;
          break;
        case ToastType.info:
          backgroundColor = AppColors.primaryTint;
          accentColor = const Color(0xFF5B50EC);
          iconData = LucideIcons.info;
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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
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
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.topCenter,
          child: Dismissible(
            key: const ValueKey('toast_floating_msg'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Left vertical color accent indicator
                      Container(
                        width: 4,
                        color: widget.accentColor,
                      ),
                      const SizedBox(width: 12),
                      // Icon badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          widget.iconData,
                          color: widget.accentColor,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dismiss button
                      GestureDetector(
                        onTap: widget.onDismiss,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                          child: Icon(
                            LucideIcons.x,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            size: 16,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast "campagne promo" façon vignette moderne
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
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
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
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF5B50EC).withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B50EC).withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                    // Vignette image
                    Container(
                      width: 84,
                      color: AppColors.background,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.background,
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF5B50EC),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.background,
                                child: Icon(
                                  LucideIcons.imageOff,
                                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                                  size: 22,
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF5B50EC),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.megaphone,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B50EC).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.sparkles,
                                        size: 11,
                                        color: Color(0xFF5B50EC),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Nouvelle offre',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5B50EC),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: widget.onDismiss,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      LucideIcons.x,
                                      size: 15,
                                      color: AppColors.textSecondary.withValues(alpha: 0.5),
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
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Text(
                                  'Taper pour voir',
                                  style: TextStyle(
                                    color: Color(0xFF5B50EC),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 13,
                                  color: Color(0xFF5B50EC),
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
