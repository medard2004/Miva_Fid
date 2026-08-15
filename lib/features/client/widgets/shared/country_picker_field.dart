import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_radius.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/widgets/components/app_tap_scale.dart';
import 'package:miva_fid/features/client/widgets/shared/phone_input_with_country_picker.dart'
    show CountryInfo, kCountries;
import 'package:miva_fid/l10n/gen/app_localizations.dart';

/// Sélecteur de pays — même liste et même présentation (drapeau, nom,
/// recherche) que le sélecteur d'indicatif de [PhoneInputWithCountryPicker],
/// mais pour le pays du profil : ne stocke/affiche que le nom, pas
/// l'indicatif téléphonique.
class CountryPickerField extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final String hintText;

  const CountryPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.hintText = 'Sélectionner un pays',
  });

  CountryInfo? _matchByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final c in kCountries) {
      if (c.name == name) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _matchByName(value);

    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTapScale(
              scaleDown: 0.98,
              onTap: () async {
                final picked = await showModalBottomSheet<CountryInfo>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => _CountryPickerModal(selected: selected),
                );
                if (picked != null) {
                  onChanged(picked.name);
                  state.didChange(picked.name);
                }
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: state.hasError ? AppColors.error : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    if (selected != null) ...[
                      Text(selected.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        selected?.name ?? hintText,
                        style: selected == null
                            ? AppTextStyles.bodyMedium(
                                color: AppColors.inkMuted(opacity: 0.4))
                            : AppTextStyles.bodyMedium(),
                      ),
                    ),
                    const Icon(LucideIcons.chevronDown,
                        size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  state.errorText!,
                  style: AppTextStyles.bodySmall(color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CountryPickerModal extends StatefulWidget {
  final CountryInfo? selected;

  const _CountryPickerModal({required this.selected});

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
      _filteredCountries = kCountries
          .where((c) => c.name.toLowerCase().contains(q))
          .toList();
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
                AppLocalizations.of(context)!.countryPickerTitle,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.countryPickerSearchHint,
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
                    final isSelected = country.code == widget.selected?.code;

                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      leading:
                          Text(country.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        country.name,
                        style: AppTextStyles.bodyMedium(
                          color: isSelected ? AppColors.primary : AppColors.ink,
                        ).copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, country),
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
