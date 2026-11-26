import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/config/api_constants.dart';
import 'skeleton_loader.dart';

/// Widget réutilisable d'affichage d'image avec :
/// - aperçu local immédiat (`previewBytes`) si fourni pendant/avant l'upload
/// - cache réseau (`CachedNetworkImage`)
/// - shimmer placeholder pendant le chargement
/// - fallback propre si l'URL est absente ou en échec
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? previewBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? fallbackBackgroundColor;

  const AppNetworkImage({
    super.key,
    this.imageUrl,
    this.previewBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = LucideIcons.image,
    this.fallbackColor,
    this.fallbackBackgroundColor,
  });

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: fallbackBackgroundColor ?? Colors.black12,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: fallbackColor ?? Colors.grey.shade500,
        size: (width != null && width! < 48) ? 18 : 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (previewBytes != null && previewBytes!.isNotEmpty) {
      content = Image.memory(
        previewBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final resolvedUrl = ApiConstants.resolveMediaUrl(imageUrl);
      content = CachedNetworkImage(
        imageUrl: resolvedUrl,
        httpHeaders: ApiConstants.mediaHeaders(resolvedUrl),
        imageRenderMethodForWeb: ApiConstants.webRenderMethodFor(resolvedUrl),
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => SkeletonLoader(
          width: width,
          height: height ?? 48,
          borderRadius: borderRadius,
        ),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    } else {
      content = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }
}
