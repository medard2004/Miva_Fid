import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/utils/toast_service.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../../client/providers/settings_provider.dart';

/// Étape 2 : Localisation du commerce avec détection automatique GPS / Carte
/// et remplissage automatique des champs (Pays, Ville, Quartier/Rue).
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

  String _country = 'Togo';
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _submitting = false;
  bool _autoDetected = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingNotifierProvider);
    _country = state.country.isNotEmpty ? state.country : 'Togo';
    _countryCtrl.text = _country;
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

  Future<void> _applyReverseGeocoding(double lat, double lng) async {
    final geocoded = await LocationService.reverseGeocode(lat, lng);
    if (!mounted || geocoded == null) return;

    setState(() {
      _autoDetected = true;
      if (geocoded.country.isNotEmpty) {
        _country = geocoded.country;
        _countryCtrl.text = geocoded.country;
      }
      if (geocoded.city.isNotEmpty) {
        _cityCtrl.text = geocoded.city;
      }
      if (geocoded.address.isNotEmpty) {
        _addressCtrl.text = geocoded.address;
      }
    });
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

      // Auto-remplissage automatique des champs (Pays, Ville, Quartier)
      await _applyReverseGeocoding(position.latitude, position.longitude);

      if (mounted) {
        ToastService.showSuccess('Position et adresse détectées automatiquement !');
      }
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      ToastService.showError(_messageFor(e.reason));
    } catch (_) {
      if (!mounted) return;
      ToastService.showError(
        'Position introuvable (signal GPS faible). Choisissez sur la carte.',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String _messageFor(LocationFailureReason reason) {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return 'Activez la localisation dans les réglages de votre téléphone, ou choisissez sur la carte.';
      case LocationFailureReason.permissionDenied:
        return 'Autorisation de localisation refusée. Vous pouvez choisir la position sur la carte.';
      case LocationFailureReason.permissionDeniedForever:
        return 'Localisation bloquée. Autorisez-la dans les réglages ou choisissez sur la carte.';
    }
  }

  Future<void> _openMap() async {
    final result =
        await context.push<(double, double)>('/auth/merchant/location/map');
    if (result == null || !mounted) return;

    setState(() {
      _latitude = result.$1;
      _longitude = result.$2;
      _locating = true;
    });

    // Auto-remplissage automatique de l'adresse depuis le point choisi sur la carte
    await _applyReverseGeocoding(result.$1, result.$2);

    if (mounted) {
      setState(() => _locating = false);
      ToastService.showSuccess('Adresse mise à jour depuis la carte !');
    }
  }

  Future<void> _submit() async {
    if (_countryCtrl.text.trim().isEmpty) {
      ToastService.showError('Veuillez sélectionner votre pays.');
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      ToastService.showError('Veuillez renseigner votre ville.');
      return;
    }

    final lat = _latitude ?? 6.1319;
    final lng = _longitude ?? 1.2228;

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setCountry(_countryCtrl.text.trim());
    notifier.setCity(_cityCtrl.text.trim());
    notifier.setAddress(_addressCtrl.text.trim());
    notifier.setLocation(lat, lng);

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
    ref.watch(appBrightnessProvider);
    final hasLocation = _latitude != null && _longitude != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingProgressBar(
              current: 2,
              total: 4,
              stepTitle: 'Localisation',
              onBack: () => context.go('/auth/merchant/step1'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Localisez votre commerce',
                      style: AppTextStyles.h1().copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Définissez votre position pour remplir automatiquement votre adresse.',
                      style: AppTextStyles.bodyMd().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: Sp.md),

                    // SECTION 1: Boutons d'action compacts
                    Row(
                      children: [
                        Expanded(
                          child: _CompactLocationAction(
                            label: 'Ma position GPS',
                            icon: LucideIcons.locateFixed,
                            loading: _locating,
                            onTap: _locating ? null : _useCurrentPosition,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactLocationAction(
                            label: 'Pointer la carte',
                            icon: LucideIcons.mapPin,
                            loading: false,
                            onTap: _locating ? null : _openMap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.sm),

                    // Status Badge (compact)
                    if (hasLocation) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.successTint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.isDark
                                ? AppColors.success.withValues(alpha: 0.3)
                                : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.circleCheck,
                              color: Color(0xFF16A34A),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _autoDetected
                                    ? 'GPS : ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)} (Auto-détecté)'
                                    : 'GPS : ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                style: TextStyle(
                                  color: AppColors.isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF15803D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sp.sm),
                    ],

                    const SizedBox(height: Sp.xs),

                    // SECTION 2: Formulaire des champs
                    Row(
                      children: [
                        Text(
                          'COORDONNÉES DU COMMERCE',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (_autoDetected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.merchant.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Auto-rempli',
                              style: TextStyle(
                                color: AppColors.merchant,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pays
                          AppInput(
                            label: 'Pays *',
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
                          const SizedBox(height: Sp.sm),

                          // Ville
                          AppInput(
                            label: 'Ville *',
                            hint: 'Ex : Lomé',
                            controller: _cityCtrl,
                            prefixIcon: LucideIcons.building2,
                            textInputAction: TextInputAction.next,
                            accentColor: AppColors.merchant,
                          ),
                          const SizedBox(height: Sp.sm),

                          // Adresse / Quartier (Compacte, 1 ligne)
                          AppInput(
                            label: 'Quartier / Rue / Point de repère',
                            hint: 'Ex : Tokoin, Rue des Cocotiers',
                            controller: _addressCtrl,
                            maxLines: 1,
                            prefixIcon: LucideIcons.mapPin,
                            textInputAction: TextInputAction.done,
                            accentColor: AppColors.merchant,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Sp.lg),
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
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchant,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(LucideIcons.arrowRight, size: 18, color: Colors.white),
                  label: Text(
                    'Continuer',
                    style: AppTextStyles.labelBold().copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLocationAction extends StatelessWidget {
  const _CompactLocationAction({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: AppColors.merchant,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                icon,
                size: 16,
                color: AppColors.merchant,
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
