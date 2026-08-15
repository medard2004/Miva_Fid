import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miva_fid/core/errors/error_messages.dart';
import 'package:miva_fid/core/errors/app_error.dart';
import 'package:miva_fid/core/errors/form_error_handler.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/app_detail_bar.dart';
import 'package:miva_fid/features/client/widgets/shared/country_picker_field.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Champ du profil modifiable via [EditFieldScreen] — chacun redirige vers
/// son propre écran plutôt que de partager un formulaire unique.
enum ProfileEditableField { fullName, email, city, country }

/// Écran d'édition d'un seul champ texte du profil, atteint en tapant sur
/// la ligne correspondante dans [EditProfileScreen].
class EditFieldScreen extends ConsumerStatefulWidget {
  final ProfileEditableField field;
  const EditFieldScreen({super.key, required this.field});

  @override
  ConsumerState<EditFieldScreen> createState() => _EditFieldScreenState();
}

class _EditFieldScreenState extends ConsumerState<EditFieldScreen>
    with FormErrorHandler {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _prefillOnce(dynamic user) {
    if (_prefilled || user == null) return;
    switch (widget.field) {
      case ProfileEditableField.fullName:
        _controller.text = user.fullName as String;
        break;
      case ProfileEditableField.email:
        _controller.text = (user.email as String?) ?? '';
        break;
      case ProfileEditableField.city:
        _controller.text = (user.city as String?) ?? '';
        break;
      case ProfileEditableField.country:
        _controller.text = (user.country as String?) ?? '';
        break;
    }
    _prefilled = true;
  }

  String get _fieldKey {
    switch (widget.field) {
      case ProfileEditableField.fullName:
        return 'first_name';
      case ProfileEditableField.email:
        return 'email';
      case ProfileEditableField.city:
        return 'city';
      case ProfileEditableField.country:
        return 'country';
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context)!;
    final value = _controller.text.trim();

    try {
      await runGuarded(
        () {
          switch (widget.field) {
            case ProfileEditableField.fullName:
              return ref
                  .read(authProvider.notifier)
                  .updateFullProfile(fullName: value);
            case ProfileEditableField.email:
              return ref
                  .read(authProvider.notifier)
                  .updateFullProfile(email: value);
            case ProfileEditableField.city:
              return ref
                  .read(authProvider.notifier)
                  .updateFullProfile(city: value);
            case ProfileEditableField.country:
              return ref
                  .read(authProvider.notifier)
                  .updateFullProfile(country: value);
          }
        },
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

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    _prefillOnce(user);

    late final String title;
    late final String label;
    late final String hint;
    late final TextInputType keyboardType;
    late final FormFieldValidator<String> validator;

    switch (widget.field) {
      case ProfileEditableField.fullName:
        title = t.editProfileFullName;
        label = t.editProfileFullName;
        hint = t.editProfileFullNameHint;
        keyboardType = TextInputType.name;
        validator = fieldValidator(
          _fieldKey,
          requiredMessage: t.editProfileFullNameError,
        );
        break;
      case ProfileEditableField.email:
        title = t.editProfileEmail;
        label = t.editProfileEmail;
        hint = t.editProfileEmailHint;
        keyboardType = TextInputType.emailAddress;
        validator = fieldValidator(
          _fieldKey,
          extra: (value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
              ? null
              : ErrorMessages.emailInvalid,
        );
        break;
      case ProfileEditableField.city:
        title = t.editProfileCity;
        label = t.editProfileCity;
        hint = t.editProfileCityHint;
        keyboardType = TextInputType.text;
        validator = fieldValidator(_fieldKey);
        break;
      case ProfileEditableField.country:
        title = t.editProfileCountry;
        label = t.editProfileCountry;
        hint = t.editProfileCountryHint;
        keyboardType = TextInputType.text;
        validator = fieldValidator(_fieldKey);
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label()),
                const SizedBox(height: 6),
                if (widget.field == ProfileEditableField.country)
                  CountryPickerField(
                    value: _controller.text.isEmpty ? null : _controller.text,
                    hintText: hint,
                    onChanged: (name) {
                      clearFieldError(_fieldKey);
                      setState(() => _controller.text = name);
                    },
                    validator: validator,
                  )
                else
                  TextFormField(
                    controller: _controller,
                    keyboardType: keyboardType,
                    autofocus: true,
                    onChanged: (_) => clearFieldError(_fieldKey),
                    validator: validator,
                    style: AppTextStyles.bodyMedium(),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppTextStyles.bodyMedium(
                          color: AppColors.inkMuted(opacity: 0.4)),
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                    ),
                  ),
                const SizedBox(height: 28),
                AppButton(
                  label: t.commonSave,
                  onTap: isBusy ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
