import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Champ de mot de passe masquable du parcours de compte.
///
/// Centralisé pour que connexion, inscription, réinitialisation et changement
/// de mot de passe partagent exactement la même apparence — y compris le
/// placeholder, dont l'absence donnait l'impression d'un champ déjà rempli.
class PasswordInput extends StatelessWidget {
  const PasswordInput({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.hintText = '••••••••',
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.bodyMedium(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium(
          color: AppColors.inkMuted(opacity: 0.35),
        ),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.inkMuted(opacity: 0.55),
          ),
          onPressed: onToggle,
          tooltip: obscure ? 'Afficher' : 'Masquer',
        ),
      ),
    );
  }
}
