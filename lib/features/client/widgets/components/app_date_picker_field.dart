import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/core/theme/app_radius.dart';
import 'package:miva_fid/features/client/widgets/components/app_tap_scale.dart';

/// Champ de sélection de date — remplace les 4 implémentations
/// quasi-identiques dupliquées à travers les écrans d'authentification
/// et le profil. Reprend la même décoration que les champs de texte
/// (via `InputDecorationTheme`) pour rester visuellement identique.
class AppDatePickerField extends StatelessWidget {
  final DateTime? value;
  final void Function(DateTime) onChanged;
  final String? Function(DateTime?)? validator;
  final String hintText;
  final String helpText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialPickerDate;

  const AppDatePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.hintText = 'Sélectionner une date',
    this.helpText = 'Date de naissance',
    this.firstDate,
    this.lastDate,
    this.initialPickerDate,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        final locale = Localizations.localeOf(context).languageCode == 'fr'
            ? 'fr_FR'
            : 'en_US';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTapScale(
              scaleDown: 0.98,
              onTap: () async {
                final picked = await _showWheelDatePicker(
                  context: context,
                  initialDate:
                      value ?? initialPickerDate ?? DateTime(2000, 1, 1),
                  firstDate: firstDate ?? DateTime(1930),
                  lastDate: lastDate ??
                      DateTime.now().subtract(const Duration(days: 365 * 16)),
                  helpText: helpText,
                );
                if (picked != null) {
                  onChanged(picked);
                  state.didChange(picked);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: state.hasError ? AppColors.error : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(right: 10),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(
                                color: AppColors.border, width: 1)),
                      ),
                      child: Icon(LucideIcons.calendarDays,
                          size: 18,
                          color: AppColors.inkMuted(opacity: 0.5)),
                    ),
                    Expanded(
                      child: Text(
                        value == null
                            ? hintText
                            : DateFormat('d MMMM yyyy', locale).format(value!),
                        style: value == null
                            ? AppTextStyles.bodyMedium(
                                color: AppColors.inkMuted(opacity: 0.4))
                            : AppTextStyles.bodyMedium()
                                .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  state.errorText!,
                  style: AppTextStyles.bodySmall(color: AppColors.error)
                      .copyWith(color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<DateTime?> _showWheelDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String helpText,
  }) {
    var tempDate = initialDate;
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                  child: Row(
                    children: [
                      Text(helpText,
                          style: AppTextStyles.label()
                              .copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context, tempDate),
                        child: Text('OK',
                            style: AppTextStyles.label(
                                    color: AppColors.primary)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border),
                SizedBox(
                  height: 216,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness:
                          AppColors.isDark ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: AppTextStyles.bodyMedium()
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      onDateTimeChanged: (date) => tempDate = date,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
