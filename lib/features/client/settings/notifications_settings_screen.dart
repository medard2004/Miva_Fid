import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/client_proximity_provider.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final cards = ref.watch(walletProvider);
    final proximityState = ref.watch(clientProximityProvider);
    final isDark = AppColors.isDark;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(
        title: t.settingsNotifications,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Proximité section
            Text(
              'ALERTES ET PROXIMITÉ',
              style: AppTextStyles.label().copyWith(
                color: AppColors.inkMuted(opacity: 0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: proximityState.enabled
                              ? AppColors.primaryTint
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.radar,
                          size: 20,
                          color: proximityState.enabled
                              ? AppColors.primary
                              : AppColors.inkMuted(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alertes de proximité',
                              style: AppTextStyles.bodyMedium().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Recevez une notification quand vous passez près de vos commerces favoris.',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.inkMuted(opacity: 0.7),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _NotificationToggle(
                        enabled: proximityState.enabled,
                        onChanged: (value) async {
                          await ref
                              .read(clientProximityProvider.notifier)
                              .toggle(context, value);
                        },
                      ),
                    ],
                  ),

                  // Bannière GPS désactivé
                  if (proximityState.needsLocationService) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A181C)
                            : const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF7F1D1D)
                              : const Color(0xFFFDA4AF),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPinOff,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'La localisation de votre téléphone est désactivée. Activez le GPS pour détecter les commerces proches.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => ref
                                .read(clientProximityProvider.notifier)
                                .openLocationSettings(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(0, 32),
                            ),
                            child: Text(
                              'Activer GPS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Bannière permission refusée
                  if (proximityState.needsPermission) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF362810)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF78350F)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              proximityState.isPermissionDeniedForever
                                  ? 'Autorisation de localisation refusée définitivement. Ouvrez les paramètres pour l\'accorder manuellement.'
                                  : 'Autorisation de localisation requise pour détecter les commerces proches.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              if (proximityState.isPermissionDeniedForever) {
                                ref
                                    .read(clientProximityProvider.notifier)
                                    .openAppSettings();
                              } else {
                                ref
                                    .read(clientProximityProvider.notifier)
                                    .toggle(context, true);
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(0, 32),
                            ),
                            child: Text(
                              proximityState.isPermissionDeniedForever
                                  ? 'Paramètres'
                                  : 'Autoriser',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notifications par commerce
            Text(
              'NOTIFICATIONS PAR ÉTABLISSEMENT',
              style: AppTextStyles.label().copyWith(
                color: AppColors.inkMuted(opacity: 0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Activez ou désactivez les alertes pour chacun de vos commerces.',
              style: AppTextStyles.caption().copyWith(
                color: AppColors.inkMuted(opacity: 0.7),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            if (cards.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.bellOff,
                        size: 36,
                        color: AppColors.inkMuted(opacity: 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Aucune carte de fidélité',
                        style: AppTextStyles.bodyMedium().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rejoignez des commerces pour gérer leurs notifications ici.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.inkMuted(opacity: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                        _NotifToggleRow(
                          cardId: cards[i].id,
                          name: cards[i].restaurantName,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotifToggleRow extends ConsumerWidget {
  final String cardId;
  final String name;
  const _NotifToggleRow({required this.cardId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(notificationPrefsProvider.select((p) => p[cardId] ?? true));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.store,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _NotificationToggle(
            enabled: enabled,
            onChanged: (value) => ref
                .read(notificationPrefsProvider.notifier)
                .toggle(cardId, value),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: enabled,
      label: 'Notifications',
      onTap: () => onChanged(!enabled),
      child: GestureDetector(
        onTap: () => onChanged(!enabled),
        child: SizedBox(
          width: 54,
          height: 38,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: enabled ? AppColors.primary : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment:
                    enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    enabled ? LucideIcons.bell : LucideIcons.bellOff,
                    size: 12,
                    color: enabled ? AppColors.primary : AppColors.inkMuted(),
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
