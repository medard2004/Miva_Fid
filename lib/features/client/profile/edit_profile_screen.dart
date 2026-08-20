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
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/features/client/widgets/shared/user_avatar.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Modification du profil : photo, puis chaque information (nom, date de
/// naissance, email, ville, mot de passe) sur sa propre ligne — un tap
/// redirige vers l'écran dédié à ce champ, plutôt qu'un formulaire unique.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with FormErrorHandler {
  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Le serveur refuse au-delà de 5 Mo : on redimensionne à la source
      // plutôt que de laisser l'upload échouer après coup.
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    // image_picker rend un fichier dans le cache tmp de l'OS, purgeable à
    // tout moment : on le copie dans le répertoire documents de l'app pour
    // que l'aperçu local reste valide le temps de l'upload.
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
      // Sert seulement d'aperçu optimiste le temps de l'upload : une fois
      // celui-ci résolu (succès ou échec), l'état ne référence plus ce
      // fichier — inutile de le laisser traîner dans les documents.
      unawaited(persisted.delete().catchError((_) => persisted));
    }
  }

  Future<void> _removeAvatar() async {
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
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LucideIcons.image, color: AppColors.ink),
                title: Text(t.editProfilePhotoChange,
                    style: AppTextStyles.bodyMedium()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar();
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Colors.red),
                  title: Text(
                    t.editProfilePhotoRemove,
                    style: AppTextStyles.bodyMedium(color: Colors.red),
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
    final dateFormatLocale =
        Localizations.localeOf(context).languageCode == 'fr'
            ? 'fr_FR'
            : 'en_US';
    final birthDateLabel = user?.birthDate != null
        ? DateFormat('d MMM yyyy', dateFormatLocale).format(user!.birthDate!)
        : t.editProfileNotSet;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: t.editProfileTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      leading: UserAvatar(
                        fullName: user?.fullName ?? '',
                        photoUrl: user?.photoUrl,
                        localImage: auth.localAvatar,
                        radius: 19,
                        isLoading: isBusy,
                      ),
                      label: t.editProfilePhotoLabel,
                      value: t.editProfilePhotoChange,
                      onTap: isBusy
                          ? () {}
                          : () => _showPhotoOptions(user?.photoUrl != null),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: LucideIcons.user,
                      label: t.editProfileFullName,
                      value: user?.fullName ?? t.editProfileNotSet,
                      isIncomplete: user?.fullName == null || user!.fullName.isEmpty,
                      onTap: () => context.push(
                        '/client/profile/edit/name',
                      ),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: LucideIcons.cake,
                      label: t.editProfileBirthDate,
                      value: birthDateLabel,
                      isIncomplete: user?.birthDate == null,
                      onTap: () =>
                          context.push('/client/profile/edit/birthdate'),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: LucideIcons.mail,
                      label: t.editProfileEmail,
                      value: user?.email ?? t.editProfileNotSet,
                      isIncomplete: user?.email == null || user!.email!.isEmpty,
                      onTap: () => context.push('/client/profile/edit/email'),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: LucideIcons.globe,
                      label: t.editProfileCountry,
                      value: user?.country ?? t.editProfileNotSet,
                      isIncomplete: user?.country == null || user!.country!.isEmpty,
                      onTap: () =>
                          context.push('/client/profile/edit/country'),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: LucideIcons.mapPin,
                      label: t.editProfileCity,
                      value: user?.city ?? t.editProfileNotSet,
                      isIncomplete: user?.city == null || user!.city!.isEmpty,
                      onTap: () => context.push('/client/profile/edit/city'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(t.editProfileSecurity,
                  style: AppTextStyles.label(color: AppColors.primary)
                      .copyWith(letterSpacing: 0.6)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (user?.isSocialUser ?? false)
                      _InfoRow(
                        icon: LucideIcons.link,
                        label: t.editProfileAuthMethod,
                        value: t.editProfileConnectedVia(
                          user!.socialProviderLabel!,
                        ),
                        onTap: () {},
                      )
                    else
                      _InfoRow(
                        icon: LucideIcons.lock,
                        label: t.changePasswordTitle,
                        value: '••••••••',
                        onTap: () =>
                            context.push('/client/profile/verify-password'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne d'information cliquable : tap redirige vers l'écran d'édition du
/// champ affiché, à la manière de la ligne "Paramètres" de l'écran Profil.
class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final String value;
  final bool isIncomplete;
  final VoidCallback onTap;

  const _InfoRow({
    this.icon,
    this.leading,
    required this.label,
    required this.value,
    this.isIncomplete = false,
    required this.onTap,
  }) : assert(icon != null || leading != null);

  @override
  Widget build(BuildContext context) {
    return AppTapScale(
      onTap: onTap,
      scaleDown: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.ink),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: AppTextStyles.bodySmall(
                              color: AppColors.inkMuted(opacity: 0.55))),
                      if (isIncomplete) ...[
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.triangleAlert,
                            size: 12, color: AppColors.warning),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium()
                        .copyWith(fontWeight: FontWeight.w600),
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
    );
  }
}
