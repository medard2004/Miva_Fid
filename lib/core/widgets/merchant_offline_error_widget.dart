import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/core/api_exceptions.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Widget universel d'état d'erreur et hors-ligne pour les écrans marchand.
///
/// Remplace tout affichage brut d'exception technique ou de message Dio
/// par un visuel soigné, compréhensible et orienté action (réessai + consultation du cache).
class MerchantOfflineErrorWidget extends ConsumerWidget {
  const MerchantOfflineErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.message,
    this.isCompact = false,
  });

  final Object? error;
  final VoidCallback? onRetry;
  final String? title;
  final String? message;
  final bool isCompact;

  bool _isNetworkProblem(bool isOffline) {
    if (isOffline) return true;
    if (error is NetworkException) return true;
    if (error is SocketException) return true;
    final errStr = error?.toString().toLowerCase() ?? '';
    return errStr.contains('socket') ||
        errStr.contains('connection') ||
        errStr.contains('timeout') ||
        errStr.contains('network') ||
        errStr.contains('offline');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final isNet = _isNetworkProblem(isOffline);

    final displayTitle = title ??
        (isNet ? 'Mode hors ligne' : 'Impossible de charger les données');

    final displayMessage = message ??
        (isNet
            ? 'Aucune donnée en cache disponible sans connexion internet. Dès que le réseau sera rétabli, vos informations apparaîtront automatiquement.'
            : 'Une difficulté temporaire empêche de joindre le serveur. Vos données restent sécurisées.');

    final iconData = isNet ? LucideIcons.wifiOff : LucideIcons.alertTriangle;
    final iconColor = isNet ? const Color(0xFFD97706) : const Color(0xFFEF4444);
    final iconBg = isNet
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFFEE2E2);

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(Sp.md),
        margin: const EdgeInsets.symmetric(vertical: Sp.sm, horizontal: Sp.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 20, color: iconColor),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTitle,
                    style: AppTextStyles.bodyMd().copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: Sp.sm),
              IconButton(
                onPressed: () {
                  ref.read(connectivityStatusProvider.notifier).checkConnectivity();
                  onRetry?.call();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                color: AppColors.primary,
                tooltip: 'Réessayer',
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(iconData, size: 34, color: iconColor),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.h3().copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd().copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(connectivityStatusProvider.notifier).checkConnectivity();
                      onRetry?.call();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text(
                      'Réessayer',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('/merchant/offline');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.database, size: 16),
                  label: const Text(
                    'État du cache',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
