import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';

// ── Country code model ────────────────────────────────────────────────────────
class _CountryCode {
  const _CountryCode({
    required this.flag,
    required this.name,
    required this.dialCode,
    required this.digitCount,
  });
  final String flag;
  final String name;
  final String dialCode; // e.g. "+228"
  final int digitCount;  // expected local number length
}

const List<_CountryCode> _countryList = [
  _CountryCode(flag: '\uD83C\uDDF9\uD83C\uDDEC', name: 'Togo',             dialCode: '+228', digitCount: 8),
  _CountryCode(flag: '\uD83C\uDDE7\uD83C\uDDEF', name: 'Bénin',            dialCode: '+229', digitCount: 8),
  _CountryCode(flag: '\uD83C\uDDEC\uD83C\uDDED', name: 'Ghana',            dialCode: '+233', digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDE8\uD83C\uDDEE', name: 'Côte d\'Ivoire',  dialCode: '+225', digitCount: 10),
  _CountryCode(flag: '\uD83C\uDDF8\uD83C\uDDF3', name: 'Sénégal',          dialCode: '+221', digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDF2\uD83C\uDDF1', name: 'Mali',             dialCode: '+223', digitCount: 8),
  _CountryCode(flag: '\uD83C\uDDE7\uD83C\uDDEB', name: 'Burkina Faso',     dialCode: '+226', digitCount: 8),
  _CountryCode(flag: '\uD83C\uDDF3\uD83C\uDDEA', name: 'Niger',            dialCode: '+227', digitCount: 8),
  _CountryCode(flag: '\uD83C\uDDE8\uD83C\uDDF2', name: 'Cameroun',         dialCode: '+237', digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDE8\uD83C\uDDEC', name: 'Congo (RDC)',      dialCode: '+243', digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDF3\uD83C\uDDEC', name: 'Nigeria',          dialCode: '+234', digitCount: 10),
  _CountryCode(flag: '\uD83C\uDDE6\uD83C\uDDF4', name: 'Angola',           dialCode: '+244', digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDF2\uD83C\uDDE6', name: 'Maroc',            dialCode: '+212', digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDE9\uD83C\uDDFF', name: 'Algérie',          dialCode: '+213', digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDF9\uD83C\uDDF3', name: 'Tunisie',          dialCode: '+216', digitCount: 8),
  _CountryCode(flag: '\uD83C\uDDEB\uD83C\uDDF7', name: 'France',           dialCode: '+33',  digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDE7\uD83C\uDDEA', name: 'Belgique',         dialCode: '+32',  digitCount: 9),
  _CountryCode(flag: '\uD83C\uDDE8\uD83C\uDDE6', name: 'Canada',           dialCode: '+1',   digitCount: 10),
  _CountryCode(flag: '\uD83C\uDDFA\uD83C\uDDF8', name: 'États-Unis',       dialCode: '+1',   digitCount: 10),
];


class MerchantStep1Screen extends ConsumerStatefulWidget {
  const MerchantStep1Screen({super.key});

  @override
  ConsumerState<MerchantStep1Screen> createState() =>
      _MerchantStep1ScreenState();
}

class _MerchantStep1ScreenState extends ConsumerState<MerchantStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController();
  late final _phoneCtrl = TextEditingController();
  late final _addressCtrl = TextEditingController();
  late final _customCategoryCtrl = TextEditingController();
  bool _isCustomCategory = false;

  // Country code picker state — Togo by default
  _CountryCode _selectedCountry = _countryList.first;

  static const List<String> _categories = [
    'Supérette',
    'Salon de coiffure',
    'Salon de beauté',
    'Pâtisserie',
    'Pharmacie',
    'Hôtel',
    'Restaurant',
    'Boutique',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingNotifierProvider);
    _nameCtrl.text = state.commerceName;
    _phoneCtrl.text = state.phone;
    _addressCtrl.text = state.address;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setCommerceName(_nameCtrl.text.trim());
    // Save phone with dial code prefix
    notifier.setPhone('${_selectedCountry.dialCode} ${_phoneCtrl.text.trim()}');
    notifier.setAddress(_addressCtrl.text.trim());
    // If the user typed a custom category, use it instead of "Autre"
    if (_isCustomCategory && _customCategoryCtrl.text.trim().isNotEmpty) {
      notifier.setCommerceType(_customCategoryCtrl.text.trim());
    }

    context.go('/auth/merchant/step2');
  }

  // ── Country picker bottom sheet ───────────────────────────────────────────
  void _showCountryPicker() {
    final searchCtrl = TextEditingController();
    List<_CountryCode> filtered = List.from(_countryList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: Sp.md),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                    child: Row(
                      children: [
                        Text(
                          'Code pays',
                          style: AppTextStyles.h3().copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.md,
                      vertical: Sp.sm,
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (q) {
                        setModalState(() {
                          filtered = _countryList
                              .where((c) =>
                                  c.name.toLowerCase().contains(q.toLowerCase()) ||
                                  c.dialCode.contains(q))
                              .toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher un pays...',
                        hintStyle: AppTextStyles.bodyMd().copyWith(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.bgLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Country list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSelected = c.dialCode == _selectedCountry.dialCode &&
                            c.name == _selectedCountry.name;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Text(
                            c.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            c.name,
                            style: AppTextStyles.bodyMd().copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.dialCode,
                                style: AppTextStyles.bodyMd().copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCountry = c;
                              // Clear phone digits when switching country
                              _phoneCtrl.clear();
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.xs, top: Sp.md),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodyMd().copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: label),
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    const inputDecorationTheme = InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: Rd.input,
        borderSide: BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Rd.input,
        borderSide: BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Rd.input,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Rd.input,
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: Rd.input,
        borderSide: BorderSide(color: AppColors.danger, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const OnboardingProgressBar(current: 1, total: 4),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Sp.md),
                      Text(
                        'Étape 1 sur 4',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        'Présentez votre commerce',
                        style: AppTextStyles.h1().copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: Sp.xs),
                      Text(
                        'Vos infos apparaîtront sur la carte fidélité.',
                        style: AppTextStyles.bodyMd().copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sp.lg),

                      // 1. Nom du commerce *
                      _buildFieldLabel('Nom du commerce'),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                        decoration: inputDecorationTheme.copyWith(
                          hintText: 'Ex : Restaurant La Belle',
                          hintStyle: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Veuillez renseigner le nom de votre commerce'
                            : null,
                      ),

                       // 2. Catégorie *
                      _buildFieldLabel('Catégorie'),
                      DropdownButtonFormField<String>(
                        value: _isCustomCategory
                            ? 'Autre'
                            : (state.commerceType.isEmpty ? null : state.commerceType),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _isCustomCategory = v == 'Autre';
                              if (!_isCustomCategory) {
                                _customCategoryCtrl.clear();
                              }
                            });
                            ref
                                .read(onboardingNotifierProvider.notifier)
                                .setCommerceType(v);
                          }
                        },
                        hint: Text(
                          'Sélectionnez une catégorie',
                          style: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                        validator: (v) => v == null
                            ? 'Veuillez sélectionner une catégorie'
                            : null,
                        style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                        decoration: inputDecorationTheme,
                        dropdownColor: Colors.white,
                        borderRadius: Rd.card,
                      ),

                      // 2b. Custom category field (shown only when "Autre" is selected)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _isCustomCategory
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: Sp.sm),
                                  TextFormField(
                                    controller: _customCategoryCtrl,
                                    autofocus: true,
                                    textInputAction: TextInputAction.next,
                                    style: AppTextStyles.bodyMd().copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: inputDecorationTheme.copyWith(
                                      hintText: 'Ex : Bijouterie, Librairie…',
                                      hintStyle: AppTextStyles.bodyMd().copyWith(
                                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      enabledBorder: const OutlineInputBorder(
                                        borderRadius: Rd.input,
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (_isCustomCategory &&
                                          (v == null || v.trim().isEmpty)) {
                                        return 'Veuillez préciser le type de commerce';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      // 3. Téléphone
                      _buildFieldLabel('Téléphone'),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                            _selectedCountry.digitCount,
                          ),
                        ],
                        style: AppTextStyles.bodyMd()
                            .copyWith(color: AppColors.textPrimary),
                        decoration: inputDecorationTheme.copyWith(
                          hintText: List.filled(
                            _selectedCountry.digitCount,
                            '0',
                          ).join(' '),
                          hintStyle: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.6),
                          ),
                          // Tappable country code prefix
                          prefixIcon: GestureDetector(
                            onTap: _showCountryPicker,
                            child: Container(
                              margin: const EdgeInsets.only(
                                left: 4,
                                right: 4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountry.flag,
                                    style:
                                        const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedCountry.dialCode,
                                    style:
                                        AppTextStyles.bodyMd().copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) {
                            return 'Veuillez renseigner le téléphone de votre commerce';
                          }
                          if (value.length != _selectedCountry.digitCount) {
                            return 'Le numéro doit contenir ${_selectedCountry.digitCount} chiffres pour ${_selectedCountry.name}';
                          }
                          return null;
                        },
                      ),

                      // 4. Ville *
                      _buildFieldLabel('Ville'),
                      TextFormField(
                        controller: _addressCtrl,
                        textInputAction: TextInputAction.done,
                        style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                        decoration: inputDecorationTheme.copyWith(
                          hintText: 'Ex : Lomé',
                          hintStyle: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Veuillez renseigner la ville de votre commerce'
                            : null,
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
                  onPressed: _next,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
