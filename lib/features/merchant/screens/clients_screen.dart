import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';
import '../providers/clients_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/client_row.dart';
import '../../client/providers/settings_provider.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _selectedFilter = 'Tous';
  static const _filters = ['Tous', 'Argent', 'Or', 'Platine', '+30j'];
  bool _isSearching = false;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: Sp.md),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text('Filtrer les clients', style: AppTextStyles.h3()),
                const SizedBox(height: Sp.md),
                Wrap(
                  spacing: Sp.sm,
                  runSpacing: Sp.sm,
                  children: _filters.map((f) {
                    final isSelected = _selectedFilter == f;
                    return ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: AppColors.merchant.withValues(alpha: 0.08),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 14,
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
                        ref.read(hideMerchantNavProvider.notifier).state = _isSearching || f != 'Tous';
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: Sp.xl),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final clientsAsync = ref.watch(clientsNotifierProvider);
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final merchant = merchantAsync.value;

    final isFilteredOrSearching = _isSearching || _selectedFilter != 'Tous';

    return PopScope(
      canPop: !isFilteredOrSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isFilteredOrSearching) {
          setState(() {
            _isSearching = false;
            _selectedFilter = 'Tous';
          });
          ref.read(clientsNotifierProvider.notifier).search('');
          ref.read(clientsNotifierProvider.notifier).setFilter('Tous');
          ref.read(hideMerchantNavProvider.notifier).state = false;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const SizedBox(height: Sp.sm),

          // 1. Header with Actions
          if (isFilteredOrSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 24),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _selectedFilter = 'Tous';
                        _searchController.clear();
                      });
                      ref.read(clientsNotifierProvider.notifier).search('');
                      ref.read(clientsNotifierProvider.notifier).setFilter('Tous');
                      ref.read(hideMerchantNavProvider.notifier).state = false;
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (q) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          ref.read(clientsNotifierProvider.notifier).search(q);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: _selectedFilter != 'Tous' ? 'Rechercher (Filtre: $_selectedFilter)...' : 'Rechercher un client...',
                        hintStyle: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchController.text.isNotEmpty || _isSearching
                            ? IconButton(
                                icon: Icon(LucideIcons.x, color: AppColors.textSecondary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(clientsNotifierProvider.notifier).search('');
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      style: AppTextStyles.bodyMd().copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Mes clients',
                      style: AppTextStyles.h1().copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.search, color: AppColors.textPrimary, size: 20),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                          ref.read(hideMerchantNavProvider.notifier).state = true;
                          _searchFocusNode.requestFocus();
                        },
                        tooltip: 'Rechercher',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: Sp.xs),
                      IconButton(
                        onPressed: _showFilterModal,
                        icon: Icon(LucideIcons.slidersHorizontal, color: AppColors.textPrimary, size: 20),
                        tooltip: 'Filtrer',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: Sp.xs),
                      IconButton(
                        icon: Icon(LucideIcons.fileDown, color: AppColors.textPrimary, size: 20),
                        onPressed: () => AppToast.info(context, 'Export bientôt disponible'),
                        tooltip: 'Exporter',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: Sp.xs),
                      IconButton(
                        icon: const Icon(LucideIcons.userPlus, color: Colors.white, size: 20),
                        onPressed: () => AppToast.info(context, 'Ajout manuel bientôt disponible'),
                        tooltip: 'Ajouter',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.merchant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: Sp.md),
          
          // 2. Mini Stats
          if (!isFilteredOrSearching) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(Sp.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          clientsAsync.when(
                            loading: () => const SizedBox(height: 18, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => Text('-', style: AppTextStyles.h3()),
                            data: (list) => Text('${list.length}', style: AppTextStyles.h3()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(Sp.sm),
                      decoration: BoxDecoration(
                        color: AppColors.merchantTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.merchant.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Actifs', style: AppTextStyles.caption().copyWith(color: AppColors.merchant)),
                          const SizedBox(height: 2),
                          clientsAsync.when(
                            loading: () => const SizedBox(height: 18, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => Text('-', style: AppTextStyles.h3().copyWith(color: AppColors.merchant)),
                            data: (list) => Text('${list.length}', style: AppTextStyles.h3().copyWith(color: AppColors.merchant)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),
          ],
          // L'ancienne Search Bar a été supprimée, car elle est intégrée dans le Header en mode recherche.
          if (!isFilteredOrSearching) const SizedBox(height: Sp.md),

          // 4. List View
          Expanded(
            child: clientsAsync.when(
              skipLoadingOnReload: true,
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                itemCount: 6,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    height: 100,
                    decoration: const BoxDecoration(
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
                      onTap: () => ctx.go('/merchant/clients/${card.id}'),
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

          // 5. Footer Pagination
          if (!isFilteredOrSearching && (clientsAsync.valueOrNull?.length ?? 0) > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
              decoration: BoxDecoration(
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
                      side: BorderSide(color: AppColors.border),
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
                    onPressed: null, // Pagination pas encore implémentée côté requête
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
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
                          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 2),
                        Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
