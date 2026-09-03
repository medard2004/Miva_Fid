import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Checklist dynamique des exigences du mot de passe pour l'espace client.
class ClientPasswordRulesChecklist extends StatelessWidget {
  const ClientPasswordRulesChecklist({
    super.key,
    required this.password,
    this.padding = const EdgeInsets.only(top: 8, bottom: 8),
  });

  final String password;
  final EdgeInsetsGeometry padding;

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get hasDigit => password.contains(RegExp(r'[0-9]'));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRule(
            label: 'Au moins 8 caractères',
            satisfied: hasMinLength,
          ),
          const SizedBox(height: 5),
          _buildRule(
            label: '1 lettre majuscule',
            satisfied: hasUppercase,
          ),
          const SizedBox(height: 5),
          _buildRule(
            label: '1 chiffre',
            satisfied: hasDigit,
          ),
        ],
      ),
    );
  }

  Widget _buildRule({
    required String label,
    required bool satisfied,
  }) {
    return Row(
      children: [
        Icon(
          satisfied ? LucideIcons.circleCheck : LucideIcons.circle,
          size: 15,
          color: satisfied
              ? const Color(0xFF10B981)
              : AppColors.inkMuted(opacity: 0.35),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(
            fontSize: 12,
            fontWeight: satisfied ? FontWeight.w600 : FontWeight.w400,
            color: satisfied
                ? AppColors.ink
                : AppColors.inkMuted(opacity: 0.6),
          ),
        ),
      ],
    );
  }
}
