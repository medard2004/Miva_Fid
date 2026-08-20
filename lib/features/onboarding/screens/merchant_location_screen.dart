import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/utils/toast_service.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../../client/providers/settings_provider.dart';

/// Étape localisation (entre step1 et step2) : pays, ville, précisions
/// d'adresse, et position GPS — positionnée via géolocalisation directe ou
/// choix manuel sur une carte plein écran (`MerchantLocationMapScreen`).
class MerchantLocationScreen extends ConsumerStatefulWidget {
  const MerchantLocationScreen({super.key});

  @override
  ConsumerState<MerchantLocationScreen> createState() =>
      _MerchantLocationScreenState();
}

class _MerchantLocationScreenState
    extends ConsumerState<MerchantLocationScreen> {
  late final _countryCtrl = TextEditingController();
  late final _cityCtrl = TextEditingController();
  late final _addressCtrl = TextEditingController();

  String _country = '';
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingNotifierProvider);
    _country = state.country;
    _countryCtrl.text = state.country;
    _cityCtrl.text = state.city;
    _addressCtrl.text = state.address;
    _latitude = state.latitude;
    _longitude = state.longitude;
  }

  @override
  void dispose() {
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _pickCountry() {
    country_picker.showCountryPicker(
      context: context,
      searchAutofocus: true,
      onSelect: (country) => setState(() {
        _country = country.name;
        _countryCtrl.text = country.name;
      }),
    );
  }

  Future<void> _useCurrentPosition() async {
    setState(() => _locating = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      ToastService.showError(_messageFor(e.reason));
    } catch (_) {
      // `Geolocator.getCurrentPosition` sort du `timeLimit` avec une
      // `TimeoutException` brute (pas notre `LocationServiceException`) —
      // sans ce repli, un GPS lent échoue en silence, écran figé.
      if (!mounted) return;
      ToastService.showError(
        'Position introuvable (signal GPS trop faible). Réessayez ou choisissez sur la carte.',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String _messageFor(LocationFailureReason reason) {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return 'Activez la localisation dans les réglages de votre téléphone, ou choisissez la position sur la carte.';
      case LocationFailureReason.permissionDenied:
        return 'Autorisation de localisation refusée. Vous pouvez choisir la position sur la carte à la place.';
      case LocationFailureReason.permissionDeniedForever:
        return 'Localisation bloquée pour Miva-Fid. Autorisez-la dans les réglages, ou choisissez la position sur la carte.';
    }
  }

  Future<void> _openMap() async {
    final result = await context.push<(double, double)>('/auth/merchant/location/map');
    if (result == null || !mounted) return;
    setState(() {
      _latitude = result.$1;
      _longitude = result.$2;
    });
  }

  Future<void> _submit() async {
    if (_country.isEmpty) {
      ToastService.showError('Veuillez sélectionner votre pays.');
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      ToastService.showError('Veuillez renseigner votre ville.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      ToastService.showError(
        'Veuillez indiquer la position de votre commerce (position actuelle ou carte).',
      );
      return;
    }

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setCountry(_country);
    notifier.setCity(_cityCtrl.text.trim());
    notifier.setAddress(_addressCtrl.text.trim());
    notifier.setLocation(_latitude!, _longitude!);

    setState(() => _submitting = true);
    final ok = await notifier.submitLocation();
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      context.go('/auth/merchant/step2');
    } else {
      ToastService.showError('Impossible d\'enregistrer la position. Réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ces ecrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le systeme de dependances de Flutter : observer
    // la luminosite effective est leur seul declencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    final hasLocation = _latitude != null && _longitude != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: Sp.xs, right: Sp.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/auth/merchant/step1'),
                    icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                    tooltip: 'Retour',
                  ),
                  const Expanded(
                    child: OnboardingProgressBar(current: 2, total: 4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Text(
                      'Localisez votre commerce',
                      style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: Sp.sm),
                    Text(
                      'Cette position permettra à vos clients à proximité de découvrir votre commerce.',
                      style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: Sp.lg),

                    AppInput(
                      label: 'Pays',
                      hint: 'Sélectionnez votre pays',
                      controller: _countryCtrl,
                      readOnly: true,
                      onTap: _pickCountry,
                      prefixIcon: LucideIcons.globe,
                      suffixIcon: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      accentColor: AppColors.merchant,
                    ),
                    AppInput(
                      label: 'Ville',
                      hint: 'Ex : Lomé',
                      controller: _cityCtrl,
                      prefixIcon: LucideIcons.building2,
                      textInputAction: TextInputAction.next,
                      accentColor: AppColors.merchant,
                    ),
                    AppInput(
                      label: 'Plus de détails (optionnel)',
                      hint: 'Quartier, rue, point de repère…',
                      controller: _addressCtrl,
                      maxLines: 2,
                      prefixIcon: LucideIcons.mapPinned,
                      textInputAction: TextInputAction.done,
                      accentColor: AppColors.merchant,
                    ),

                    const SizedBox(height: Sp.sm),
                    Text(
                      'Position GPS',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Sp.xs),
                    Container(
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: hasLocation
                            ? AppColors.merchantTint
                            : AppColors.surface,
                        borderRadius: Rd.input,
                        border: Border.all(
                          color: hasLocation
                              ? AppColors.merchant
                              : AppColors.border,
                          width: hasLocation ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasLocation ? LucideIcons.circleCheck : LucideIcons.mapPin,
                            color: AppColors.merchant,
                            size: 22,
                          ),
                          const SizedBox(width: Sp.sm),
                          Expanded(
                            child: Text(
                              hasLocation
                                  ? 'Position définie (${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)})'
                                  : 'Aucune position sélectionnée',
                              style: AppTextStyles.bodyMd().copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.sm),
                    AppButton.merchant(
                      'Utiliser ma position actuelle',
                      onPressed: _useCurrentPosition,
                      icon: LucideIcons.locateFixed,
                      loading: _locating,
                    ),
                    const SizedBox(height: Sp.sm),
                    AppButton.outlined(
                      'Choisir sur la carte',
                      onPressed: _openMap,
                      icon: LucideIcons.map,
                      color: AppColors.merchant,
                      disabled: _locating || _submitting,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Sp.md,
                0,
                Sp.md,
                MediaQuery.of(context).padding.bottom + Sp.md,
              ),
              child: AppButton.merchant(
                'Continuer',
                onPressed: _submit,
                icon: LucideIcons.arrowRight,
                loading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
