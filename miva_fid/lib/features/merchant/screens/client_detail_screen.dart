import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/clients_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/stamp_grid_widget.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(merchantNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/merchant/clients'),
        ),
        title: Text('Détail client', style: AppTextStyles.h3()),
      ),
      body: FutureBuilder(
        future: Supabase.instance.client
            .from('loyalty_cards')
            .select('*, users(*)')
            .eq('client_id', clientId)
            .eq('merchant_id', merchantAsync.value?.id ?? '')
            .maybeSingle(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(Sp.md),
              child: Column(children: [SkeletonCard(height: 200), SkeletonCard(height: 120)]),
            );
          }
          if (snap.data == null) {
            return Center(child: Text('Client introuvable', style: AppTextStyles.bodyMd()));
          }
          final data = snap.data as Map<String, dynamic>;
          final stamps = data['stamps_count'] as int? ?? 0;
          final required = merchantAsync.value?.stampsRequired ?? 10;
          final name = (data['users'] as Map?)?['name'] as String? ?? 'Client';
          final phone = (data['users'] as Map?)?['phone'] as String? ?? '';
          final since = DateFormatter.relative(
              DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: Rd.card20,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryTint,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: AppTextStyles.h1().copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: Sp.sm),
                      Text(name, style: AppTextStyles.h2()),
                      if (phone.isNotEmpty)
                        Text(phone, style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary)),
                      Text('Membre depuis $since',
                          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                      const Divider(height: Sp.xl),
                      StampGridWidget(filled: stamps, total: required, stampSize: 30),
                      const SizedBox(height: Sp.sm),
                      Text('$stamps sur $required tampons',
                          style: AppTextStyles.mono().copyWith(color: AppColors.primary)),
                      const SizedBox(height: Sp.xs),
                      ClipRRect(
                        borderRadius: Rd.pill,
                        child: LinearProgressIndicator(
                          value: (stamps / required).clamp(0.0, 1.0),
                          color: AppColors.primary,
                          backgroundColor: AppColors.border,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.md),
                AppButton.tint('Ajouter un tampon bonus',
                    icon: Icons.add_circle_outline,
                    onPressed: () async {
                      await ref.read(clientsNotifierProvider.notifier)
                          .addBonusStamp(data['id'] as String);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tampon bonus accordé')));
                      }
                    }),
              ],
            ),
          );
        },
      ),
    );
  }
}
