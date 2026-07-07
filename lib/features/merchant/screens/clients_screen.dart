import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/clients_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/client_row.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _selectedFilter = 'Tous';
  static const _filters = ['Tous', 'Argent', 'Or', 'Platine', '+30j'];

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsNotifierProvider);
    final merchantAsync = ref.watch(merchantNotifierProvider);

    final merchant = merchantAsync.value;


    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Sp.sm),

          // 1. Title Row with "10 actifs" badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: [
                  Text(
                    'Mes clients',
                    style: AppTextStyles.h1().copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  clientsAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (list) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.merchant.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${list.length} actifs',
                        style: TextStyle(
                          color: AppColors.merchant,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),

            // 3. Export / Add Action Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.file_download_outlined, color: AppColors.textPrimary, size: 18),
                      label: Text(
                        'Exporter',
                        style: AppTextStyles.labelBold().copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.merchant,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'Ajouter',
                        style: AppTextStyles.labelBold().copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),

            // 4. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: TextField(
                onChanged: (q) => ref.read(clientsNotifierProvider.notifier).search(q),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  hintText: 'Rechercher un client...',
                  hintStyle: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: Rd.input,
                    borderSide: const BorderSide(color: AppColors.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: Rd.input,
                    borderSide: const BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: Rd.input,
                    borderSide: const BorderSide(color: AppColors.merchant, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: Sp.md),

            // 5. Custom Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: Sp.sm),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: AppColors.merchant.withOpacity(0.08),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.merchant : AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? AppColors.merchant : AppColors.border,
                          width: 1,
                        ),
                      ),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _selectedFilter = f);
                        ref.read(clientsNotifierProvider.notifier).setFilter(f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: Sp.md),

            // 6. List View
            Expanded(
              child: clientsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                  itemCount: 6,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: Rd.card,
                      ),
                    ),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('Erreur: $err', style: AppTextStyles.bodyMd()),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun client trouvé',
                        style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final card = list[i];
                      final stampReq = merchant?.stampsRequired ?? 10;
                      return ClientRow(
                        card: card,
                        stampsRequired: stampReq,
                        onTap: () => ctx.go('/merchant/clients/${card.clientId}'),
                        onSendMessage: () {
                          // Navigate to SMS tab and trigger draft campaign
                          ctx.go('/merchant/sms');
                        },
                      )
                      .animate()
                      .fadeIn(
                        duration: 350.ms,
                        delay: Duration(milliseconds: 60 * i),
                      )
                      .slideY(begin: 0.06, end: 0);
                    },
                  );
                },
              ),
            ),

            // 7. Footer Pagination
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  clientsAsync.when(
                    loading: () => const Text('1-10 sur --'),
                    error: (_, __) => const Text('1-10 sur --'),
                    data: (list) => Text(
                      '1-${list.length} sur ${list.length}',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: null, // Disabled in mockup
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      '< Préc.',
                      style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Suiv.',
                          style: AppTextStyles.caption().copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textPrimary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

