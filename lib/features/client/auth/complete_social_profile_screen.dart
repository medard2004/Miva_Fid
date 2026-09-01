import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/errors/app_error.dart';
import 'package:miva_fid/core/errors/form_error_handler.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';
import 'package:miva_fid/features/client/providers/app_providers.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/features/client/widgets/shared/phone_input_with_country_picker.dart';

/// Étape post-connexion sociale (Google/Apple).
/// Collecte : Nom complet · Téléphone · Date de naissance.
class CompleteSocialProfileScreen extends ConsumerStatefulWidget {
  const CompleteSocialProfileScreen({super.key});

  @override
  ConsumerState<CompleteSocialProfileScreen> createState() =>
      _CompleteSocialProfileScreenState();
}

class _CompleteSocialProfileScreenState
    extends ConsumerState<CompleteSocialProfileScreen> with FormErrorHandler {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneInputKey = GlobalKey<PhoneInputWithCountryPickerState>();
  final _phoneController = TextEditingController();

  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = ref.read(authProvider).user?.fullName ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Renseigne les informations que Google/Apple ne fournissent pas.
  ///
  /// Le compte existe déjà (créé par `POST /auth/social`) et la session est
  /// ouverte : cet appel complète le profil via
  /// `POST /auth/social/complete-profile`.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    clearAllFieldErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fullPhone = _phoneInputKey.currentState?.fullPhoneNumber ??
        _phoneController.text.trim();

    final success = await runGuarded(
      () => ref.read(authProvider.notifier).completeSocialProfile(
            fullName: _fullNameController.text.trim(),
            phone: fullPhone,
            birthDate: _birthDate,
          ),
      useOverlay: true,
    );

    if (!mounted || success == null) return;

    if (success) {
      ref.read(signupFlowProvider.notifier).reset();
      context.go('/client/wallet');
    } else {
      handleError(
        ref.read(authProvider).lastError,
        context: ErrorContext.completeProfile,
        formKey: _formKey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: AppColors.ink,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/client/auth');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  t.completeSocialProfileTitle,
                  style: AppTextStyles.authTitle(),
                ),
                const SizedBox(height: 20),
                Text(t.editProfileFullName, style: AppTextStyles.label()),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  keyboardType: TextInputType.name,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? t.editProfileFullNameError
                      : null,
                  style: AppTextStyles.bodyMedium(),
                  decoration: InputDecoration(
                    hintText: t.editProfileFullNameHint,
                    hintStyle: AppTextStyles.bodyMedium(
                        color: AppColors.inkMuted(opacity: 0.4)),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Text(t.commonPhoneLabel, style: AppTextStyles.label()),
                const SizedBox(height: 6),
                PhoneInputWithCountryPicker(
                  key: _phoneInputKey,
                  controller: _phoneController,
                  validator: fieldValidator(
                    'phone',
                    requiredMessage: t.authPhoneRequiredError,
                  ),
                ),
                const SizedBox(height: 16),
                Text(t.editProfileBirthDate,
                    style: AppTextStyles.label()),
                const SizedBox(height: 6),
                AppDatePickerField(
                  value: _birthDate,
                  onChanged: (date) => setState(() => _birthDate = date),
                  validator: (_) => _birthDate == null
                      ? t.authBirthDateError
                      : fieldError('birthdate'),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: t.completeProfileSubmit,
                  onTap: isBusy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
