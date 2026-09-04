import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/loyalty_level.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/tier_level_icon.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/loyalty_card_model.dart';
import '../../client/providers/settings_provider.dart';
import '../models/restaurant_account.dart';
import '../providers/clients_provider.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';

class _DisplayTier {
  final int position;
  final String label;
  final String key;
  final String? iconKey;

  const _DisplayTier({
    required this.position,
    required this.label,
    required this.key,
    this.iconKey,
  });
}


class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels <
        _scrollCtrl.position.maxScrollExtent - 400) {
      return;
    }
    ref.read(clientsNotifierProvider.notifier).loadMore();
  }

  Future<void> _refresh() =>
      ref.read(clientsNotifierProvider.notifier).refresh();

  List<_DisplayTier> _getDisplayTiers(RestaurantAccount? restaurant) {
    final rawTiers = restaurant?.loyaltyConfig['tiers'];
    if (rawTiers is List && rawTiers.isNotEmpty) {
      return List.generate(rawTiers.length, (i) {
        final item = rawTiers[i];
        final map = item is Map ? item : <String, dynamic>{};
        final position = i + 1;
        final rawName = (map['level_name'] ?? map['name']) as String?;
        final fixedLevel = LoyaltyLevel.forPosition(position);
        final label = rawName ?? fixedLevel?.label ?? 'Niveau $position';
        final key = position <= 5
            ? (fixedLevel?.key ?? rawName ?? 'custom')
            : (rawName ?? 'custom');
        final iconKey = map['icon_key'] as String?;
        return _DisplayTier(
          position: position,
          label: label,
          key: key,
          iconKey: iconKey,
        );
      });
    }

    return [
      for (final l in LoyaltyLevel.values)
        _DisplayTier(
          position: l == LoyaltyLevel.custom ? 5 : l.index + 1,
          label: l.label,
          key: l.key,
          iconKey: null,
        ),
    ];
  }

  Future<void> _openFilterSheet(
      ClientsFilter current, List<_DisplayTier> displayTiers) async {
    final applied = await showModalBottomSheet<ClientsFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClientsFilterSheet(
        initial: current,
        displayTiers: displayTiers,
      ),
    );
    if (applied == null) return;
    ref.read(clientsNotifierProvider.notifier).applyFilter(applied);
  }

  Future<void> _openSortSheet(ClientSort current) async {
    final chosen = await showModalBottomSheet<ClientSort>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trier par',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
            for (final sort in ClientSort.values)
              ListTile(
                title: Text(
                  switch (sort) {
                    ClientSort.activity => 'Activité récente',
                    ClientSort.recent => 'Plus récents',
                    ClientSort.oldest => 'Plus anciens',
                  },
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        sort == current ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: sort == current
                    ? const Icon(LucideIcons.check,
                        size: 16, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, sort),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == null || chosen == current) return;
    final notifier = ref.read(clientsNotifierProvider.notifier);
    notifier.applyFilter(notifier.currentFilter.copyWith(sort: chosen));
  }

  void _showAddClientModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+228 ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.userPlus,
                          color: Color(0xFF5B50EC),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ajouter un client',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enregistrez un nouveau client manuellement',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x,
                            size: 20, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Nom complet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ex: Koffi Mensah',
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: Icon(LucideIcons.user,
                          size: 17, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Numéro de téléphone',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '+228 90 00 00 00',
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: Icon(LucideIcons.phone,
                          size: 17, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

                        if (name.isEmpty || name.length < 2) {
                          ToastService.showError('Le nom doit comporter au moins 2 caractères');
                          return;
                        }
                        if (digitsOnly.length < 8) {
                          ToastService.showError('Veuillez saisir un numéro de téléphone valide (au moins 8 chiffres)');
                          return;
                        }
                        Navigator.pop(ctx);
                        ToastService.showSuccess(
                            'Client $name ajouté avec succès');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B50EC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer le client',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final clientsAsync = ref.watch(clientsNotifierProvider);
    final notifier = ref.read(clientsNotifierProvider.notifier);
    final currentFilter = notifier.currentFilter;
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final stampsRequired = merchantAsync.value?.stampsRequired ?? 10;
    final t = AppLocalizations.of(context)!;
    final restaurant = ref.watch(merchantAuthProvider.select((s) => s.restaurant));
    final displayTiers = _getDisplayTiers(restaurant);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER (WITH SEARCH TOGGLE & ACTION BUTTONS) ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _isSearchOpen
                  ? Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF5B50EC), width: 1.5),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              onChanged: (q) => ref
                                  .read(clientsNotifierProvider.notifier)
                                  .search(q),
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: t.merchantClientsSearchHint,
                                hintStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                                prefixIcon: const Icon(
                                  LucideIcons.search,
                                  size: 16,
                                  color: Color(0xFF5B50EC),
                                ),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(LucideIcons.x,
                                            size: 15),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          ref
                                              .read(clientsNotifierProvider.notifier)
                                              .search('');
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(LucideIcons.x,
                              size: 20, color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() {
                              _isSearchOpen = false;
                              _searchCtrl.clear();
                              ref.read(clientsNotifierProvider.notifier).search('');
                            });
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.users,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.merchantClientsTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Search Button in TopBar
                        InkWell(
                          onTap: () => setState(() => _isSearchOpen = true),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              LucideIcons.search,
                              size: 17,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add Button in TopBar
                        InkWell(
                          onTap: () => _showAddClientModal(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5B50EC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.userPlus,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Notifications Button in TopBar
                        InkWell(
                          onTap: () =>
                              context.push('/merchant/more/notifications'),
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Icon(
                                  LucideIcons.bell,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // ── EXPORT BUTTON ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => ToastService.showInfo(
                    t.merchantClientsExportToast),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.download,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.merchantClientsExportButton,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── QUICK PILLS BAR ──────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 'Tous' pill
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(clientsNotifierProvider.notifier).applyFilter(
                              currentFilter.copyWith(
                                levelKey: null,
                                inactiveDays: null,
                              ),
                            );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: (currentFilter.levelKey == null &&
                                  currentFilter.inactiveDays == null)
                              ? AppColors.surface
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(20),
                          border: (currentFilter.levelKey == null &&
                                  currentFilter.inactiveDays == null)
                              ? Border.all(
                                  color: AppColors.textPrimary,
                                  width: 1.2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.alignLeft,
                              size: 12,
                              color: (currentFilter.levelKey == null &&
                                      currentFilter.inactiveDays == null)
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.merchantClientsFilterAll,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: (currentFilter.levelKey == null &&
                                        currentFilter.inactiveDays == null)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: (currentFilter.levelKey == null &&
                                        currentFilter.inactiveDays == null)
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (displayTiers.length > 1)
                    for (final tier in displayTiers)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            final newKey = currentFilter.levelKey == tier.key
                                ? null
                                : tier.key;
                            ref.read(clientsNotifierProvider.notifier).applyFilter(
                                  currentFilter.copyWith(
                                    levelKey: newKey,
                                    inactiveDays: null,
                                  ),
                                );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: currentFilter.levelKey == tier.key
                                  ? AppColors.surface
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(20),
                              border: currentFilter.levelKey == tier.key
                                  ? Border.all(
                                      color: AppColors.textPrimary,
                                      width: 1.2)
                                  : null,
                            ),
                            child: Text(
                              tier.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: currentFilter.levelKey == tier.key
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: currentFilter.levelKey == tier.key
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  // Inactive 30d pill
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        final newDays = currentFilter.inactiveDays == 30
                            ? null
                            : 30;
                        ref.read(clientsNotifierProvider.notifier).applyFilter(
                              currentFilter.copyWith(
                                inactiveDays: newDays,
                                levelKey: null,
                              ),
                            );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: currentFilter.inactiveDays == 30
                              ? AppColors.surface
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(20),
                          border: currentFilter.inactiveDays == 30
                              ? Border.all(
                                  color: AppColors.textPrimary,
                                  width: 1.2)
                              : null,
                        ),
                        child: Text(
                          t.merchantClientsFilterInactive30d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: currentFilter.inactiveDays == 30
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: currentFilter.inactiveDays == 30
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _FilterButton(
                    activeCount: currentFilter.activeFilterCount,
                    onTap: () => _openFilterSheet(currentFilter, displayTiers),
                  ),
                  const SizedBox(width: 6),
                  _QuickPill(
                    label: switch (currentFilter.sort) {
                      ClientSort.activity => 'Activité',
                      ClientSort.recent => 'Récents',
                      ClientSort.oldest => 'Anciens',
                    },
                    icon: LucideIcons.arrowUpDown,
                    isSelected: currentFilter.sort != ClientSort.activity,
                    onTap: () => _openSortSheet(currentFilter.sort),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── CLIENTS LIST ────────────────────────────────────────────
            Expanded(
              child: clientsAsync.when(
                skipLoadingOnReload: true,
                loading: () => ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, __) => Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Impossible de charger les clients',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () =>
                            ref.invalidate(clientsNotifierProvider),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Réessayer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (state) {
                  final listBody = state.clients.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  controller: _scrollCtrl,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  itemCount: state.clients.length +
                                      (state.hasMore || state.isLoadingMore
                                          ? 1
                                          : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    if (index >= state.clients.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        child: Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.4),
                                          ),
                                        ),
                                      );
                                    }
                                    final client = state.clients[index];
                                    return _ClientCard(
                                      client: client,
                                      stampsRequired: stampsRequired,
                                      onTap: () => context
                                          .push('/merchant/clients/${client.id}'),
                                      onSms: () {
                                        final cName = client.client?.name ?? 'Client';
                                        final cPhone = client.client?.phone ?? '';
                                        final cInitials = client.client?.initials ??
                                            (cName.isNotEmpty ? cName[0].toUpperCase() : 'C');
                                        context.push(
                                          '/merchant/sms/conversation',
                                          extra: {
                                            'clientName': cName,
                                            'clientPhone': cPhone,
                                            'clientInitials': cInitials,
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              // ── PAGINATION FOOTER ──────────────────────
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        t.merchantClientsPaginationInfo(
                                            '1',
                                            state.clients.length.toString(),
                                            state.total.toString()),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        Text(
                                          t.merchantClientsPrevious,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            t.merchantClientsNext,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                  return listBody;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.users,
                    size: 36,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Aucun client trouvé',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ajustez vos filtres ou revenez plus tard :\nles nouveaux clients apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: activeCount > 0 ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activeCount > 0 ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.slidersHorizontal,
              size: 13,
              color:
                  activeCount > 0 ? AppColors.primary : AppColors.textPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              'Filtres',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: activeCount > 0
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickPill extends StatelessWidget {
  const _QuickPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientsFilterSheet extends StatefulWidget {
  const _ClientsFilterSheet({
    required this.initial,
    required this.displayTiers,
  });

  final ClientsFilter initial;
  final List<_DisplayTier> displayTiers;

  @override
  State<_ClientsFilterSheet> createState() => _ClientsFilterSheetState();
}

class _ClientsFilterSheetState extends State<_ClientsFilterSheet> {
  static const _inactivityPresets = [7, 15, 30, 60, 90];

  late int? _inactiveDays = widget.initial.inactiveDays;
  late String? _levelKey = widget.initial.levelKey;
  late int? _minCycles = widget.initial.minCycles;
  final _customDaysCtrl = TextEditingController();
  bool _showCustomDays = false;

  @override
  void initState() {
    super.initState();
    final preset = widget.initial.inactiveDays;
    if (preset != null && !_inactivityPresets.contains(preset)) {
      _showCustomDays = true;
      _customDaysCtrl.text = '$preset';
    }
  }

  @override
  void dispose() {
    _customDaysCtrl.dispose();
    super.dispose();
  }

  int? get _effectiveInactiveDays {
    if (!_showCustomDays) return _inactiveDays;
    return int.tryParse(_customDaysCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtres',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _inactiveDays = null;
                      _levelKey = null;
                      _minCycles = null;
                      _customDaysCtrl.clear();
                      _showCustomDays = false;
                    }),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Réinitialiser',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _sectionTitle('Inactivité'),
            _chipWrap([
              for (final days in _inactivityPresets)
                _FilterChip(
                  label: '${days}j',
                  isSelected: !_showCustomDays && _inactiveDays == days,
                  onTap: () => setState(() {
                    _showCustomDays = false;
                    _inactiveDays = _inactiveDays == days ? null : days;
                  }),
                ),
              _FilterChip(
                label: 'Autre',
                isSelected: _showCustomDays,
                onTap: () => setState(() {
                  if (_showCustomDays) {
                    _showCustomDays = false;
                    _customDaysCtrl.clear();
                  } else {
                    _showCustomDays = true;
                    _inactiveDays = null;
                  }
                }),
              ),
            ]),
            if (_showCustomDays)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _customDaysCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: 'jours',
                      suffixStyle:
                          TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),

            _sectionTitle('Niveau de fidélité'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tier in widget.displayTiers)
                    _LevelChip(
                      tier: tier,
                      isSelected: _levelKey == tier.key,
                      onTap: () => setState(() {
                        _levelKey = _levelKey == tier.key ? null : tier.key;
                      }),
                    ),
                ],
              ),
            ),

            _sectionTitle('Programme terminé'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FilterChip(
                    label: 'Peu importe',
                    isSelected: _minCycles == null,
                    onTap: () => setState(() => _minCycles = null),
                  ),
                  _FilterChip(
                    label: 'Au moins 1 fois',
                    isSelected: _minCycles == 1,
                    onTap: () => setState(() => _minCycles = 1),
                  ),
                  _FilterChip(
                    label: '3 fois ou +',
                    isSelected: _minCycles == 3,
                    onTap: () => setState(
                        () => _minCycles = _minCycles == 3 ? null : 3),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: () {
                    final filter = ClientsFilter(
                      search: widget.initial.search,
                      inactiveDays: _effectiveInactiveDays,
                      levelKey: _levelKey,
                      minCycles: _minCycles,
                      sort: widget.initial.sort,
                    );
                    Navigator.pop(context, filter);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Appliquer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _chipWrap(List<Widget> chips) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(spacing: 6, runSpacing: 6, children: chips),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  final _DisplayTier tier;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fixedLevel = LoyaltyLevel.forPosition(tier.position);
    final color = fixedLevel?.color ?? const Color(0xFF8B5CF6);
    final background = fixedLevel?.background ?? const Color(0xFFF3E8FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? background : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TierLevelIcon(
              position: tier.position,
              iconKey: tier.iconKey,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              tier.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.stampsRequired,
    required this.onTap,
    required this.onSms,
  });

  final LoyaltyCardModel client;
  final int stampsRequired;
  final VoidCallback onTap;
  final VoidCallback onSms;

  static const _avatarColors = [
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    final name = client.client?.name ?? 'Client';
    final phone = client.client?.phone ?? '';
    final initials = client.client?.initials ??
        (name.isNotEmpty ? name[0].toUpperCase() : '?');
    final avatarUrl = client.client?.avatarUrl;

    final hash = name.hashCode;
    final avatarColor = _avatarColors[hash.abs() % _avatarColors.length];

    final lastActivity = client.lastActivityAt == null
        ? null
        : DateFormatter.relative(client.lastActivityAt!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    image: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? null
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (client.levelName != null) ...[
                            const SizedBox(width: 6),
                            _LevelBadge(
                              name: client.levelName!,
                              position: client.levelPosition,
                              iconKey: client.levelIconKey,
                            ),
                          ],
                          if (client.cyclesCompleted > 0) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'Programme terminé ${client.cyclesCompleted} fois',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.successTint,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.repeat_rounded,
                                        size: 10, color: AppColors.success),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${client.cyclesCompleted}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastActivity == null
                            ? phone
                            : '$phone • $lastActivity',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      LucideIcons.eye,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onSms,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.name, this.position, this.iconKey});

  final String name;
  final int? position;
  final String? iconKey;

  @override
  Widget build(BuildContext context) {
    final fixedLevel = position == null ? null : LoyaltyLevel.forPosition(position!);
    final color = fixedLevel?.color ?? AppColors.textSecondary;
    final background = fixedLevel?.background ?? AppColors.background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TierLevelIcon(position: position, iconKey: iconKey, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
