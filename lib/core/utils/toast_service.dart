import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/config/api_constants.dart';
import '../router/app_router.dart';
import '../router/client_router.dart';
import '../router/merchant_router.dart';
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
  final String? restaurantName;
  final String? restaurantLogo;
  final VoidCallback? onTap;

  _ToastRequest({
    required this.message,
    required this.type,
    required this.duration,
    this.title,
    this.imageUrl,
    this.campaignId,
    this.restaurantName,
    this.restaurantLogo,
    this.onTap,
  });

  bool get isCampaign => campaignId != null && campaignId!.isNotEmpty;
}

class ToastService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Clé du navigateur actif (liée à `clientNavigatorKey` côté Client,
  /// `merchantNavigatorKey` côté Marchand, ou `rootNavigatorKey` par défaut).
  static GlobalKey<NavigatorState> navigatorKey = rootNavigatorKey;

  static GlobalKey<NavigatorState> get _activeNavigatorKey {
    for (final candidate in [
      navigatorKey,
      clientNavigatorKey,
      merchantNavigatorKey,
      rootNavigatorKey,
    ]) {
      if (candidate.currentState?.overlay != null &&
          candidate.currentContext != null) {
        return candidate;
      }
    }
    return navigatorKey;
  }

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
    final entry = _overlayEntry;
    _overlayEntry = null;
    _isShowing = false;
    if (entry != null) {
      try {
        entry.remove();
      } catch (_) {}
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
      restaurantName: next.restaurantName,
      restaurantLogo: next.restaurantLogo,
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
    String? restaurantName,
    String? restaurantLogo,
    String? notificationId,
    Map<String, dynamic>? notificationData,
    Duration duration = const Duration(seconds: 6),
  }) {
    final activeKey = _activeNavigatorKey;
    final context = activeKey.currentContext;
    if (context == null) {
      _showSnackBarFallback('$title : $body', ToastType.info, duration);
      return;
    }

    if (notificationId != null && markSeen(notificationId)) return;

    void onTap() {
      hideCurrent();
      final ctx = _activeNavigatorKey.currentContext;
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
      restaurantName: restaurantName,
      restaurantLogo: restaurantLogo,
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
      restaurantName: request.restaurantName,
      restaurantLogo: request.restaurantLogo,
      onTap: request.onTap,
    );
  }

  /// Affiche un toast d'établissement (tampon, points, récompense, cashback...)
  /// avec le logo et le nom de l'établissement et la redirection au clic.
  static void showEstablishmentNotification({
    required String title,
    required String body,
    String? restaurantName,
    String? restaurantLogo,
    bool isWarning = false,
    Map<String, dynamic>? notificationData,
    Duration duration = const Duration(seconds: 4),
  }) {
    final type = isWarning ? ToastType.warning : ToastType.success;
    final displayTitle = (restaurantName != null &&
            restaurantName.isNotEmpty &&
            !title.contains(restaurantName))
        ? restaurantName
        : (title.isNotEmpty ? title : restaurantName);
    final displayMessage = body.isNotEmpty ? body : title;

    void onTap() {
      hideCurrent();
      final ctx = _activeNavigatorKey.currentContext;
      if (ctx == null || notificationData == null) return;
      final destination = resolveNotificationDestination(
        type: notificationData['type'] as String? ?? '',
        data: notificationData,
        title: title,
        body: body,
      );
      navigateToNotificationDestination(ctx, destination);
    }

    final request = _ToastRequest(
      message: displayMessage,
      type: type,
      duration: duration,
      title: displayTitle,
      restaurantName: restaurantName,
      restaurantLogo: restaurantLogo,
      onTap: notificationData != null ? onTap : null,
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
      restaurantName: request.restaurantName,
      restaurantLogo: request.restaurantLogo,
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
    String? restaurantName,
    String? restaurantLogo,
    VoidCallback? onTap,
  }) {
    final activeKey = _activeNavigatorKey;
    final context = activeKey.currentContext;
    final overlay = activeKey.currentState?.overlay;
    if (context == null || overlay == null) {
      _showSnackBarFallback(message, type, duration);
      return;
    }

    final isCampaign = campaignId != null && campaignId.isNotEmpty;

    late Widget toast;
    if (isCampaign) {
      toast = _CampaignToastWidget(
        title: title ?? message,
        body: message,
        imageUrl: imageUrl,
        restaurantName: restaurantName,
        restaurantLogo: restaurantLogo,
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
        title: title,
        message: message,
        restaurantLogo: restaurantLogo,
        backgroundColor: backgroundColor,
        accentColor: accentColor,
        iconData: iconData,
        onDismiss: hideCurrent,
        onTap: onTap,
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

    overlay.insert(_overlayEntry!);
    _isShowing = true;
    _timer = Timer(duration, hideCurrent);
  }

  static void _showSnackBarFallback(
    String message,
    ToastType type,
    Duration duration,
  ) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    final color = switch (type) {
      ToastType.success => AppColors.success,
      ToastType.error => AppColors.danger,
      ToastType.warning => AppColors.warningDark,
      ToastType.info => AppColors.primary,
    };
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
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
  final String? title;
  final String message;
  final String? restaurantLogo;
  final Color backgroundColor;
  final Color accentColor;
  final IconData iconData;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const _ToastWidget({
    this.title,
    required this.message,
    this.restaurantLogo,
    required this.backgroundColor,
    required this.accentColor,
    required this.iconData,
    required this.onDismiss,
    this.onTap,
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
                child: GestureDetector(
                  onTap: widget.onTap,
                  behavior: HitTestBehavior.opaque,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Left vertical color accent indicator
                        Container(
                          width: 4,
                          color: widget.accentColor,
                        ),
                        const SizedBox(width: 12),
                        // Establishment logo or icon badge
                        _buildLeadingBadge(),
                        const SizedBox(width: 12),
                        // Text content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.title != null && widget.title!.isNotEmpty) ...[
                                  Text(
                                    widget.title!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  widget.message,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: (widget.title != null && widget.title!.isNotEmpty)
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                    fontSize: (widget.title != null && widget.title!.isNotEmpty) ? 12 : 13,
                                    fontWeight: (widget.title != null && widget.title!.isNotEmpty)
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildLeadingBadge() {
    final logoUrl = widget.restaurantLogo;
    final fallback = Container(
      width: 34,
      height: 34,
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
    );

    if (logoUrl == null || logoUrl.isEmpty) return fallback;

    final resolved = ApiConstants.resolveMediaUrl(logoUrl);
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: resolved,
        httpHeaders: ApiConstants.mediaHeaders(resolved),
        imageRenderMethodForWeb: ApiConstants.webRenderMethodFor(resolved),
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
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
  final String? restaurantName;
  final String? restaurantLogo;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _CampaignToastWidget({
    required this.title,
    required this.body,
    required this.onDismiss,
    required this.onTap,
    this.imageUrl,
    this.restaurantName,
    this.restaurantLogo,
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
    final thumbUrl = (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
        ? widget.imageUrl
        : (widget.restaurantLogo != null && widget.restaurantLogo!.isNotEmpty
            ? widget.restaurantLogo
            : null);
    final hasImage = thumbUrl != null;
    final hasLogo = widget.restaurantLogo != null && widget.restaurantLogo!.isNotEmpty;
    final badgeLabel = (widget.restaurantName != null && widget.restaurantName!.isNotEmpty)
        ? widget.restaurantName!
        : 'Nouvelle offre';

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
                    // Vignette image (image campagne ou logo établissement)
                    Container(
                      width: 84,
                      color: AppColors.background,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl:
                                  ApiConstants.resolveMediaUrl(thumbUrl),
                              httpHeaders: ApiConstants.mediaHeaders(
                                  ApiConstants.resolveMediaUrl(
                                      thumbUrl)),
                              imageRenderMethodForWeb:
                                  ApiConstants.webRenderMethodFor(
                                      ApiConstants.resolveMediaUrl(
                                          thumbUrl)),
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
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5B50EC).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hasLogo) ...[
                                          ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: ApiConstants.resolveMediaUrl(widget.restaurantLogo!),
                                              httpHeaders: ApiConstants.mediaHeaders(
                                                  ApiConstants.resolveMediaUrl(widget.restaurantLogo!)),
                                              imageRenderMethodForWeb: ApiConstants.webRenderMethodFor(
                                                  ApiConstants.resolveMediaUrl(widget.restaurantLogo!)),
                                              width: 14,
                                              height: 14,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(
                                                LucideIcons.store,
                                                size: 11,
                                                color: Color(0xFF5B50EC),
                                              ),
                                            ),
                                          ),
                                        ] else
                                          const Icon(
                                            LucideIcons.sparkles,
                                            size: 11,
                                            color: Color(0xFF5B50EC),
                                          ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            badgeLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF5B50EC),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
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
