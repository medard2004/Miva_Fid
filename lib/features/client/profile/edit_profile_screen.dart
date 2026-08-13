import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

/// Modification du profil : identité, coordonnées, photo, et accès au
/// changement de mot de passe.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with FormErrorHandler {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  DateTime? _birthDate;
  bool _prefilled = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Pré-remplit les champs une seule fois.
  ///
  /// Refaire l'affectation à chaque build écraserait la saisie en cours dès
  /// que le provider émet (par exemple après un upload d'avatar).
  void _prefillOnce(dynamic user) {
    if (_prefilled || user == null) return;
    _fullNameController.text = user.fullName as String;
    _emailController.text = (user.email as String?) ?? '';
    _cityController.text = (user.city as String?) ?? '';
    _birthDate = user.birthDate as DateTime?;
    _prefilled = true;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final city = _cityController.text.trim();

    try {
      await runGuarded(
        () => ref.read(authProvider.notifier).updateFullProfile(
              fullName: _fullNameController.text.trim(),
              email: email.isNotEmpty ? email : null,
              city: city.isNotEmpty ? city : null,
              birthDate: _birthDate,
            ),
        useOverlay: true,
        loadingMessage: t.editProfileSaving,
      );
      if (!mounted) return;
      showSuccessToast(ErrorMessages.profileSaveSuccess);
      context.pop();
    } catch (e) {
      if (mounted) {
        handleError(e,
            context: ErrorContext.updateProfile, formKey: _formKey);
      }
    }
  }

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

    try {
      await runGuarded(
        () => ref.read(authProvider.notifier).updateAvatar(File(picked.path)),
        useOverlay: true,
      );
      if (mounted) showSuccessToast(ErrorMessages.avatarUpdateSuccess);
    } catch (e) {
      if (mounted) handleError(e, context: ErrorContext.updateAvatar);
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

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    _prefillOnce(auth.user);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: t.editProfileTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      UserAvatar(
                        fullName: auth.user?.fullName ?? '',
                        photoUrl: auth.user?.photoUrl,
                        localImage: auth.localAvatar,
                        radius: 48,
                        isLoading: isBusy,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isBusy ? null : _pickAvatar,
                        child: Text(
                          t.editProfilePhotoChange,
                          style: AppTextStyles.bodyMedium(
                                  color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (auth.user?.photoUrl != null)
                        TextButton(
                          onPressed: isBusy ? null : _removeAvatar,
                          child: Text(
                            t.editProfilePhotoRemove,
                            style: AppTextStyles.bodySmall(
                                color: AppColors.inkMuted(opacity: 0.5)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(t.editProfileFullName, style: AppTextStyles.label()),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  keyboardType: TextInputType.name,
                  onChanged: (_) => clearFieldError('first_name'),
                  validator: fieldValidator(
                    'first_name',
                    requiredMessage: t.editProfileFullNameError,
                  ),
                  decoration:
                      InputDecoration(hintText: t.editProfileFullNameHint),
                ),
                const SizedBox(height: 16),
                Text(t.editProfileBirthDate, style: AppTextStyles.label()),
                const SizedBox(height: 6),
                AppDatePickerField(
                  value: _birthDate,
                  onChanged: (date) => setState(() => _birthDate = date),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(t.editProfileEmail, style: AppTextStyles.label()),
                    const SizedBox(width: 8),
                    StatusBadge(label: t.commonOptional),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => clearFieldError('email'),
                  validator: fieldValidator(
                    'email',
                    extra: (value) => value.contains('@') && value.contains('.')
                        ? null
                        : ErrorMessages.emailInvalid,
                  ),
                  decoration: InputDecoration(hintText: t.editProfileEmailHint),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(t.editProfileCity, style: AppTextStyles.label()),
                    const SizedBox(width: 8),
                    StatusBadge(label: t.commonOptional),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cityController,
                  onChanged: (_) => clearFieldError('city'),
                  validator: fieldValidator('city'),
                  decoration: InputDecoration(hintText: t.editProfileCityHint),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: t.commonSave,
                  onTap: isBusy ? null : _save,
                ),
                const SizedBox(height: 24),
                Text(t.editProfileSecurity, style: AppTextStyles.label()),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(LucideIcons.lock,
                        size: 20, color: AppColors.inkMuted(opacity: 0.7)),
                    title: Text(t.changePasswordTitle,
                        style: AppTextStyles.bodyMedium()),
                    trailing: Icon(LucideIcons.chevronRight,
                        size: 18, color: AppColors.inkMuted(opacity: 0.4)),
                    onTap: () =>
                        context.push('/client/profile/verify-password'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
