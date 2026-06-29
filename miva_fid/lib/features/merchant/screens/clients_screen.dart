import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/clients_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/client_row.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  static const _filters = ['Tous', 'Proches récompense', 'VIP', 'Inactifs'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsNotifierProvider);
    final merchantAsync = ref.watch(merchantNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, 0),
              child: Row(
                children: [
                  Text('Mes Clients', style: AppTextStyles.h1()),
                  const Spacer(),
                  clientsAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (list) => AppBadge(list.length.toString(), color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: TextField(
                onChanged: (q) => ref.read(clientsNotifierProvider.notifier).search(q),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  hintText: 'Rechercher un client...',
                  hintStyle: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: Rd.input,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: _filters.map((f) => Padding(
                  padding: const EdgeInsets.only(right: Sp.sm),
                  child: FilterChip(
                    label: Text(f),
                    selected: false,
                    onSelected: (_) => ref.read(clientsNotifierProvider.notifier).setFilter(f),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: Sp.sm),
            Expanded(
              child: clientsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(Sp.md),
                  itemCount: 6,
                  itemBuilder: (_, __) => const SkeletonListTile(),
                ),
                error: (_, __) => const EmptyState(
                  message: 'Erreur de chargement',
                  icon: Icons.error_outline,
                ),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        message: 'Aucun client trouvé',
                        subtitle: 'Vos clients apparaîtront ici après leur première visite',
                        icon: Icons.people_outline,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(Sp.md),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final card = list[i];
                          final stampReq = merchantAsync.value?.stampsRequired ?? 10;
                          return ClientRow(
                            card: card,
                            stampsRequired: stampReq,
                            onTap: () => ctx.go('/merchant/clients/${card.clientId}'),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
