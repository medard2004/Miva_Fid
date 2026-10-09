import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/notifications_provider.dart';

/// Bouton cloche réactif pour l'espace marchand avec badge temps réel.
class MerchantNotificationBellButton extends ConsumerWidget {
  final double size;

  const MerchantNotificationBellButton({
    super.key,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(merchantUnreadCountProvider);

    return Semantics(
      button: true,
      label: unreadCount > 0
          ? 'Notifications, $unreadCount non lues'
          : 'Notifications',
      child: InkWell(
        onTap: () => context.push('/merchant/more/notifications'),
        borderRadius: BorderRadius.circular(size / 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.bell,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
