import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum _ButtonVariant {
  primary,
  ghost,
  danger,
  tint,
  merchant,
  success,
  outlined,
}

class AppButton extends StatefulWidget {
  const AppButton._({
    super.key,
    required this.label,
    required this.variant,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = true,
    this.color,
    this.backgroundColor,
    this.textColor,
  });

  factory AppButton.primary(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool disabled = false,
    bool fullWidth = true,
  }) =>
      AppButton._(
        label: label,
        variant: _ButtonVariant.primary,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        disabled: disabled,
        fullWidth: fullWidth,
      );

  factory AppButton.ghost(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool disabled = false,
    bool fullWidth = true,
  }) =>
      AppButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.ghost,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        disabled: disabled,
        fullWidth: fullWidth,
      );

  factory AppButton.danger(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool disabled = false,
    bool fullWidth = true,
  }) =>
      AppButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.danger,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        disabled: disabled,
        fullWidth: fullWidth,
      );

  factory AppButton.tint(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool disabled = false,
    bool fullWidth = true,
  }) =>
      AppButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.tint,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        disabled: disabled,
        fullWidth: fullWidth,
      );

  factory AppButton.merchant(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool disabled = false,
    bool fullWidth = true,
  }) =>
      AppButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.merchant,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        disabled: disabled,
        fullWidth: fullWidth,
      );

  factory AppButton.success(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool disabled = false,
    bool fullWidth = true,
  }) =>
      AppButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.success,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        disabled: disabled,
        fullWidth: fullWidth,
      );

  factory AppButton.outlined(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool disabled = false,
    bool fullWidth = true,
    Color? color,
  }) =>
      AppButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.outlined,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        disabled: disabled,
        fullWidth: fullWidth,
        color: color,
      );

  /// Custom button (e.g. vitrine)
  factory AppButton.custom(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool disabled = false,
    bool fullWidth = true,
    Color? backgroundColor,
    Color? textColor,
  }) =>
      AppButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.tint,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        disabled: disabled,
        fullWidth: fullWidth,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );

  final String label;
  final _ButtonVariant variant;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool disabled;
  final bool fullWidth;
  final Color? color;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.loading || widget.onPressed == null;

    final colors = _resolveColors();
    final bg = widget.backgroundColor ?? colors.$1;
    final fg = widget.textColor ?? colors.$2;
    final border = colors.$3;

    Widget child = Row(
      mainAxisSize:
          widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          ),
          const SizedBox(width: Sp.sm),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: Sp.sm),
        ],
        Text(
          widget.label,
          style: AppTextStyles.labelBold().copyWith(color: fg),
        ),
      ],
    );

    Widget button = AnimatedScale(
      scale: _pressed && !isDisabled ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 14),
          decoration: BoxDecoration(
            color: isDisabled ? AppColors.border : bg,
            borderRadius: Rd.button,
            border: border != null
                ? Border.all(color: isDisabled ? AppColors.border : border, width: 1.5)
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  (Color, Color, Color?) _resolveColors() {
    final accent = widget.color;
    switch (widget.variant) {
      case _ButtonVariant.primary:
        return (AppColors.primary, Colors.white, null);
      case _ButtonVariant.ghost:
        return (Colors.transparent, AppColors.primary, null);
      case _ButtonVariant.danger:
        return (AppColors.danger, Colors.white, null);
      case _ButtonVariant.tint:
        return (AppColors.primaryTint, AppColors.primary, null);
      case _ButtonVariant.merchant:
        return (AppColors.merchant, Colors.white, null);
      case _ButtonVariant.success:
        return (AppColors.success, Colors.white, null);
      case _ButtonVariant.outlined:
        return (Colors.transparent, accent ?? AppColors.primary, accent ?? AppColors.primary);
    }
  }
}
