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
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Édition de la date de naissance, atteinte en tapant sur la ligne
/// correspondante dans [EditProfileScreen].
class EditBirthDateScreen extends ConsumerStatefulWidget {
  const EditBirthDateScreen({super.key});

  @override
  ConsumerState<EditBirthDateScreen> createState() =>
      _EditBirthDateScreenState();
}

class _EditBirthDateScreenState extends ConsumerState<EditBirthDateScreen>
    with FormErrorHandler {
  final _formKey = GlobalKey<FormState>();
  DateTime? _birthDate;
  bool _prefilled = false;

  void _prefillOnce(dynamic user) {
    if (_prefilled || user == null) return;
    _birthDate = user.birthDate as DateTime?;
    _prefilled = true;
  }

  Future<void> _save() async {
    clearAllFieldErrors();
    final t = AppLocalizations.of(context)!;
    try {
      await runGuarded(
        () => ref
            .read(authProvider.notifier)
            .updateFullProfile(birthDate: _birthDate),
        useOverlay: true,
        loadingMessage: t.editProfileSaving,
      );
      if (!mounted) return;
      showSuccessToast(ErrorMessages.profileSaveSuccess);
      context.pop();
    } catch (e) {
      if (mounted) {
        handleError(e, context: ErrorContext.updateProfile, formKey: _formKey);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    _prefillOnce(user);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppDetailBar(title: t.editProfileBirthDate),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.editProfileBirthDate, style: AppTextStyles.label()),
                const SizedBox(height: 6),
                AppDatePickerField(
                  value: _birthDate,
                  onChanged: (date) {
                    clearFieldError('birthdate');
                    setState(() => _birthDate = date);
                  },
                  validator: (_) => fieldError('birthdate'),
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
