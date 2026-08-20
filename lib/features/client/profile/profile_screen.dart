import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/providers/wallet_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_section_header.dart';
import 'package:miva_fid/features/client/widgets/shared/notification_bell_button.dart';
import 'package:miva_fid/features/client/widgets/shared/user_avatar.dart';

/// Profil — juste l'essentiel : identité, un coup d'œil chiffré, code de
/// parrainage, et un accès unique vers Paramètres pour tout le reste
/// (apparence, langue, notifications, déconnexion). Les informations
/// détaillées (nom/téléphone/naissance/email) ne vivent qu'à un seul
/// endroit : la modale d'édition, pour ne pas les afficher deux fois.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final cards = ref.watch(walletProvider);
    final rewards = ref.watch(rewardsProvider);
    final unreadNotifs =
        ref.watch(notificationsProvider).where((n) => !n.isRead).length;
    final dateFormatLocale =
        Localizations.localeOf(context).languageCode == 'fr'
            ? 'fr_FR'
            : 'en_US';

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: EmptyState(
            icon: LucideIcons.user,
            title: t.profileNotConnectedTitle,
            message: t.profileNotConnectedMessage,
            action: AppButton(
              label: t.profileSignIn,
              fullWidth: false,
              onTap: () => context.go('/client/auth'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              title: t.profileTitle,
              actions: [NotificationBellButton(unreadCount: unreadNotifs)],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AppTapScale(
                              onTap: user.isProfileIncomplete
                                  ? () => context.push('/client/profile/edit')
                                  : null,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  UserAvatar(
                                    fullName: user.fullName,
                                    photoUrl: user.photoUrl,
                                    localImage:
                                        ref.watch(authProvider).localAvatar,
                                    radius: 32,
                                  ),
                                  if (user.isProfileIncomplete)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.warning,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.surface,
                                              width: 2),
                                        ),
                                        child: const Icon(
                                          LucideIcons.triangleAlert,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName
                                        : t.profileTitle,
                                    style: AppTextStyles.titleMedium()
                                        .copyWith(fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.maskedPhoneNumber,
                                    style: AppTextStyles.monoSmall(
                                        color:
                                            AppColors.inkMuted(opacity: 0.65)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.profileMemberSince(
                                        user.memberSinceDate(dateFormatLocale)),
                                    style: AppTextStyles.bodySmall(
                                        color:
                                            AppColors.inkMuted(opacity: 0.5)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: t.profileEditProfile,
                          variant: AppButtonVariant.outline,
                          icon: LucideIcons.pencil,
                          height: 46,
                          // Écran plein et non plus feuille modale : l'édition
                          // porte désormais la photo de profil et l'accès au
                          // changement de mot de passe, qui poussent leurs
                          // propres écrans.
                          onTap: () => context.push('/client/profile/edit'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                            value: '${cards.length}', label: t.profileCards),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                            value: '${rewards.length}', label: t.profileOffers),
                      ),
                    ],
                  ),
                  if (user.isBirthdayMonth) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      backgroundColor: AppColors.primaryTint,
                      bordered: false,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('🎂', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.profileBirthdayBannerTitle,
                                  style: AppTextStyles.label(
                                      color: AppColors.primaryDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.profileBirthdayBannerMessage,
                                  style: AppTextStyles.bodySmall(
                                      color: AppColors.inkMuted(opacity: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppCard(
                    onTap: () => context.push('/client/settings'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(LucideIcons.settings,
                              size: 18, color: AppColors.ink),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t.profileSettings,
                                  style: AppTextStyles.bodyMedium()
                                      .copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                t.profileSettingsSubtitle,
                                style: AppTextStyles.bodySmall(
                                    color: AppColors.inkMuted(opacity: 0.55)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 18, color: AppColors.inkMuted(opacity: 0.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
