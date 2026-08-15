import 'dart:async';
import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../../features/client/core/theme/app_colors.dart';
import '../../features/client/core/theme/app_text_styles.dart';

enum ToastType { success, error, warning, info }

class ToastService {
  // We keep this for compatibility if any place still uses it, but we will use Overlay.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static bool _isShowing = false;

  /// Hide the current toast (if any)
  static void hideCurrent() {
    if (_isShowing && _overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
    _timer?.cancel();
    _timer = null;

    // Fallback if using standard SnackBar somewhere
    messengerKey.currentState?.hideCurrentSnackBar();
  }

  /// Show a global toast notification using Overlay
  static void show({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Make sure we have a navigator context
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    hideCurrent();

    // Fond teinté doux (même famille que les badges de statut) plutôt qu'un
    // aplat saturé : le texte et l'icône reprennent la couleur sémantique
    // pleine, ce qui reste lisible dans les deux thèmes — contrairement à
    // l'ancien fond rouge vif + texte clair/sombre selon le thème, illisible
    // en mode sombre.
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

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        backgroundColor: backgroundColor,
        accentColor: accentColor,
        iconData: iconData,
        onDismiss: hideCurrent,
      ),
    );

    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay != null) {
      overlay.insert(_overlayEntry!);
      _isShowing = true;
      _timer = Timer(duration, hideCurrent);
    }
  }

  /// Helper for Success
  static void showSuccess(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(message: message, type: ToastType.success, duration: duration);
  }

  /// Helper for Error
  static void showError(String message,
      {Duration duration = const Duration(seconds: 4)}) {
    show(message: message, type: ToastType.error, duration: duration);
  }

  /// Helper for Warning
  static void showWarning(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(message: message, type: ToastType.warning, duration: duration);
  }

  /// Helper for Info
  static void showInfo(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(message: message, type: ToastType.info, duration: duration);
  }
}

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
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Positioned(
      top: statusBarHeight + 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
        ),
      ),
    );
  }
}
