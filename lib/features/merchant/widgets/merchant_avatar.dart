import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({
    super.key,
    required this.logoUrl,
    required this.initials,
    this.radius = 24.0,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.onTap,
  });

  final String? logoUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? AppColors.merchant;
    final double size = radius * 2;
    final bool hasUrl = logoUrl != null && logoUrl!.trim().isNotEmpty;

    Widget childWidget;

    if (hasUrl) {
      final url = logoUrl!.trim();
      Widget imageFallback() => _buildInitials(effectiveBgColor);

      if (url.startsWith('http://') || url.startsWith('https://')) {
        childWidget = CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => imageFallback(),
          errorWidget: (_, __, ___) => imageFallback(),
        );
      } else {
        try {
          childWidget = Image.file(
            File(url),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => imageFallback(),
          );
        } catch (_) {
          childWidget = imageFallback();
        }
      }
    } else {
      childWidget = _buildInitials(effectiveBgColor);
    }

    final avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: childWidget,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildInitials(Color bg) {
    final cleanInitials = initials.trim().isEmpty ? 'RS' : initials.trim();
    final double fontSize = radius * 0.7;

    return Container(
      width: radius * 2,
      height: radius * 2,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        cleanInitials,
        style: AppTextStyles.monoLg().copyWith(
          color: textColor,
          fontSize: fontSize.clamp(10.0, 28.0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
