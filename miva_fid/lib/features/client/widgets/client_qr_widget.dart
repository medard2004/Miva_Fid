import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ClientQrWidget extends StatelessWidget {
  const ClientQrWidget({super.key, this.size = 180});
  final double size;

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final qrData = jsonEncode({'clientId': uid, 'app': 'mivafid'});

    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card20,
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.12),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            size: size,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
          ),
          const SizedBox(height: Sp.sm),
          Text('Montrez ce code au caissier',
              style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
