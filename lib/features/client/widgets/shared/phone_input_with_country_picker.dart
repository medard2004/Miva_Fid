import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Modèle représentatif d'un pays avec son nom, indicatif et drapeau.
class CountryInfo {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  /// Nombre de chiffres attendu pour le numéro local (hors indicatif).
  ///
  /// `null` pour les pays dont la longueur varie trop pour qu'un contrôle
  /// strict soit fiable côté client — la validation finale reste de toute
  /// façon faite par le serveur (`phone:AUTO,INTERNATIONAL`).
  final int? digitCount;

  const CountryInfo({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    this.digitCount,
  });
}

const List<CountryInfo> kCountries = [
  CountryInfo(name: 'Togo', code: 'TG', dialCode: '+228', flag: '🇹🇬', digitCount: 8),
  CountryInfo(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷', digitCount: 9),
  CountryInfo(
      name: 'Côte d\'Ivoire', code: 'CI', dialCode: '+225', flag: '🇨🇮', digitCount: 10),
  CountryInfo(name: 'Sénégal', code: 'SN', dialCode: '+221', flag: '🇸🇳', digitCount: 9),
  CountryInfo(name: 'Bénin', code: 'BJ', dialCode: '+229', flag: '🇧🇯', digitCount: 8),
  CountryInfo(name: 'Cameroun', code: 'CM', dialCode: '+237', flag: '🇨🇲', digitCount: 9),
  CountryInfo(name: 'Mali', code: 'ML', dialCode: '+223', flag: '🇲🇱', digitCount: 8),
  CountryInfo(name: 'Burkina Faso', code: 'BF', dialCode: '+226', flag: '🇧🇫', digitCount: 8),
  CountryInfo(name: 'Gabon', code: 'GA', dialCode: '+241', flag: '🇬🇦'),
  CountryInfo(name: 'Congo', code: 'CG', dialCode: '+242', flag: '🇨🇬', digitCount: 9),
  CountryInfo(name: 'RDC', code: 'CD', dialCode: '+243', flag: '🇨🇩', digitCount: 9),
  CountryInfo(name: 'Niger', code: 'NE', dialCode: '+227', flag: '🇳🇪', digitCount: 8),
  CountryInfo(name: 'Guinée', code: 'GN', dialCode: '+224', flag: '🇬🇳'),
  CountryInfo(name: 'Ghana', code: 'GH', dialCode: '+233', flag: '🇬🇭', digitCount: 9),
  CountryInfo(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬', digitCount: 10),
  CountryInfo(name: 'Maroc', code: 'MA', dialCode: '+212', flag: '🇲🇦', digitCount: 9),
  CountryInfo(name: 'Algérie', code: 'DZ', dialCode: '+213', flag: '🇩ℤ', digitCount: 9),
  CountryInfo(name: 'Tunisie', code: 'TN', dialCode: '+216', flag: '🇹🇳', digitCount: 8),
  CountryInfo(name: 'États-Unis', code: 'US', dialCode: '+1', flag: '🇺🇸', digitCount: 10),
  CountryInfo(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦', digitCount: 10),
  CountryInfo(name: 'Royaume-Uni', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  CountryInfo(name: 'Belgique', code: 'BE', dialCode: '+32', flag: '🇧🇪', digitCount: 9),
  CountryInfo(name: 'Suisse', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
  CountryInfo(name: 'Allemagne', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
];

/// Champ de saisie du numéro de téléphone avec sélecteur d'indicateur pays.
class PhoneInputWithCountryPicker extends StatefulWidget {
  final TextEditingController controller;
  final String? initialCountryCode;
  final ValueChanged<CountryInfo>? onCountryChanged;
  final String? Function(String?)? validator;
  final String hintText;

  const PhoneInputWithCountryPicker({
    super.key,
    required this.controller,
    this.initialCountryCode = '+228',
    this.onCountryChanged,
    this.validator,
    this.hintText = '90 12 34 56',
  });

  @override
  State<PhoneInputWithCountryPicker> createState() =>
      PhoneInputWithCountryPickerState();
}

class PhoneInputWithCountryPickerState
    extends State<PhoneInputWithCountryPicker> {
  late CountryInfo selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = kCountries.firstWhere(
      (c) => c.dialCode == widget.initialCountryCode,
      orElse: () => kCountries.first,
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _CountryPickerModal(
          selectedCountry: selectedCountry,
          onSelect: (country) {
            setState(() => selectedCountry = country);
            widget.onCountryChanged?.call(country);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  /// Retourne le numéro de téléphone complet avec l'indicatif.
  String get fullPhoneNumber {
    final raw = widget.controller.text.trim();
    if (raw.isEmpty) return '';
    return '${selectedCountry.dialCode} $raw';
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final parentError = widget.validator?.call(value);
        if (parentError != null) return parentError;
        final digits = value?.trim() ?? '';
        final expected = selectedCountry.digitCount;
        if (digits.isNotEmpty && expected != null && digits.length != expected) {
          return AppLocalizations.of(context)!
              .phoneDigitsError(expected, selectedCountry.name);
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.bodyMedium().copyWith(letterSpacing: 1.2),
      decoration: InputDecoration(
        hintText: widget.hintText,
        // Sans style explicite, le placeholder héritait de la couleur du texte
        // saisi : le champ paraissait déjà rempli d'un numéro.
        hintStyle: AppTextStyles.bodyMedium(
          color: AppColors.inkMuted(opacity: 0.35),
        ).copyWith(letterSpacing: 1.2),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        prefixIcon: GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.only(left: 14, right: 10),
            margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
            decoration: BoxDecoration(
              border:
                  Border(right: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selectedCountry.flag,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  selectedCountry.dialCode,
                  style: AppTextStyles.label()
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const Icon(LucideIcons.chevronDown,
                    size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryPickerModal extends StatefulWidget {
  final CountryInfo selectedCountry;
  final ValueChanged<CountryInfo> onSelect;

  const _CountryPickerModal({
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerModal> createState() => _CountryPickerModalState();
}

class _CountryPickerModalState extends State<_CountryPickerModal> {
  late List<CountryInfo> _filteredCountries;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCountries = kCountries;
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filteredCountries = kCountries.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.dialCode.contains(q) ||
            c.code.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.phonePickerTitle,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 12),

              // Barre de recherche
              TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.phonePickerSearchHint,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _filteredCountries.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    final isSelected =
                        country.code == widget.selectedCountry.code;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Text(
                        country.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        country.name,
                        style: AppTextStyles.bodyMedium(
                          color: isSelected ? AppColors.primary : AppColors.ink,
                        ).copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: Text(
                        country.dialCode,
                        style: AppTextStyles.monoMedium(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.inkMuted(opacity: 0.6),
                        ),
                      ),
                      onTap: () => widget.onSelect(country),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
