import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/errors/app_error.dart';
import 'package:miva_fid/core/errors/error_messages.dart';
import 'package:miva_fid/core/errors/form_error_handler.dart';
import 'package:miva_fid/core/widgets/offline_action_guard.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/features/client/widgets/shared/user_avatar.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Modification du profil : photo héroïque au centre, puis informations
/// personnelles structurées en groupe iOS élégant.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with FormErrorHandler {
  Future<void> _pickAvatar() async {
    if (!OfflineActionGuard.checkCanPerform(context, ref)) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
    final docsDir = await getApplicationDocumentsDirectory();
    final persisted = await File(picked.path).copy(
      '${docsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    if (!mounted) return;

    try {
      await runGuarded(
        () => ref.read(authProvider.notifier).updateAvatar(persisted),
        useOverlay: true,
      );
      if (mounted) showSuccessToast(ErrorMessages.avatarUpdateSuccess);
    } catch (e) {
      if (mounted) handleError(e, context: ErrorContext.updateAvatar);
    } finally {
      unawaited(persisted.delete().catchError((_) => persisted));
    }
  }

  Future<void> _removeAvatar() async {
    if (!OfflineActionGuard.checkCanPerform(context, ref)) return;
    try {
      await runGuarded(
        () => ref.read(authProvider.notifier).removeAvatar(),
        useOverlay: true,
      );
      if (mounted) showSuccessToast(ErrorMessages.avatarRemoveSuccess);
    } catch (e) {
      if (mounted) handleError(e, context: ErrorContext.updateAvatar);
    }
  }

  void _showPhotoOptions(bool hasPhoto) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.image, color: AppColors.primary, size: 20),
                ),
                title: Text(t.editProfilePhotoChange,
                    style: AppTextStyles.bodyMedium().copyWith(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar();
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                  ),
                  title: Text(
                    t.editProfilePhotoRemove,
                    style: AppTextStyles.bodyMedium(color: Colors.red)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isDark = AppColors.isDark;
    final dateFormatLocale =
        Localizations.localeOf(context).languageCode == 'fr'
            ? 'fr_FR'
            : 'en_US';
    final birthDateLabel = user?.birthDate != null
        ? DateFormat('d MMMM yyyy', dateFormatLocale).format(user!.birthDate!)
        : t.editProfileNotSet;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: t.editProfileTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Section Hero Avatar ──────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: UserAvatar(
                            fullName: user?.fullName ?? '',
                            photoUrl: user?.photoUrl,
                            localImage: auth.localAvatar,
                            radius: 46,
                            isLoading: isBusy,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: AppTapScale(
                            onTap: isBusy
                                ? null
                                : () => _showPhotoOptions(user?.photoUrl != null),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppTapScale(
                      onTap: isBusy
                          ? null
                          : () => _showPhotoOptions(user?.photoUrl != null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          t.editProfilePhotoChange,
                          style: AppTextStyles.bodyMedium(color: AppColors.primary).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Informations personnelles ────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: SectionEyebrow(t.settingsAccount),
              ),
              const SizedBox(height: 8),

              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ModernInfoRow(
                      icon: LucideIcons.user,
                      label: t.editProfileFullName,
                      value: user?.fullName ?? t.editProfileNotSet,
                      isIncomplete: user?.fullName == null || user!.fullName.isEmpty,
                      onTap: () => context.push('/client/profile/edit/name'),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _ModernInfoRow(
                      icon: LucideIcons.cake,
                      label: t.editProfileBirthDate,
                      value: birthDateLabel,
                      isIncomplete: user?.birthDate == null,
                      onTap: () => context.push('/client/profile/edit/birthdate'),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _ModernInfoRow(
                      icon: LucideIcons.mail,
                      label: t.editProfileEmail,
                      value: user?.email ?? t.editProfileNotSet,
                      isIncomplete: user?.email == null || user!.email!.isEmpty,
                      onTap: () => context.push('/client/profile/edit/email'),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _ModernInfoRow(
                      icon: LucideIcons.globe,
                      label: t.editProfileCountry,
                      value: user?.country ?? t.editProfileNotSet,
                      isIncomplete: user?.country == null || user!.country!.isEmpty,
                      onTap: () => context.push('/client/profile/edit/country'),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _ModernInfoRow(
                      icon: LucideIcons.mapPin,
                      label: t.editProfileCity,
                      value: user?.city ?? t.editProfileNotSet,
                      isIncomplete: user?.city == null || user!.city!.isEmpty,
                      onTap: () => context.push('/client/profile/edit/city'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne d'information moderne avec retour tactile, icône soignée et badge d'état.
class _ModernInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isIncomplete;
  final VoidCallback onTap;

  const _ModernInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isIncomplete = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTapScale(
      onTap: onTap,
      scaleDown: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.inkMuted(opacity: 0.6),
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (isIncomplete)
                    Row(
                      children: [
                        Text(
                          value,
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.inkMuted(opacity: 0.45),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'À compléter',
                            style: AppTextStyles.bodySmall(
                              color: AppColors.warning,
                            ).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      value,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.inkMuted(opacity: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
