import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/loyalty_level.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/loyalty_card_model.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/merchant_provider.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  static const _inactivePreset = 30;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

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

  // ── Bottom sheet « Filtres » ─────────────────────────────────────────

  Future<void> _openFilterSheet(ClientsFilter current) async {
    final applied = await showModalBottomSheet<ClientsFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClientsFilterSheet(initial: current),
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

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final clientsAsync = ref.watch(clientsNotifierProvider);
    final notifier = ref.read(clientsNotifierProvider.notifier);
    final currentFilter = notifier.currentFilter;
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final stampsRequired = merchantAsync.value?.stampsRequired ?? 10;
    final t = AppLocalizations.of(context)!;

    final subtitle = clientsAsync.maybeWhen(
      data: (state) =>
          '${state.total} ${state.total > 1 ? 'clients' : 'client'}',
      orElse: () => 'Chargement...',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.merchantClientsTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => ToastService.showInfo(
                        t.merchantClientsAddSoonToast),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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
                  InkWell(
                    onTap: () => context.push('/merchant/more/notifications'),
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
                    'Export de la liste clients bientôt disponible.'),
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

            // ── SEARCH + FILTERS ROW ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (q) => ref
                            .read(clientsNotifierProvider.notifier)
                            .search(q),
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: t.merchantClientsSearchHint,
                          hintStyle: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    LucideIcons.x,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    activeCount: currentFilter.activeFilterCount,
                    onTap: () => _openFilterSheet(currentFilter),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── QUICK PILLS ─────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _QuickPill(
                    label: 'Inactifs 30j',
                    icon: LucideIcons.clock,
                    isSelected: currentFilter.inactiveDays == _inactivePreset,
                    onTap: () {
                      notifier.applyFilter(currentFilter.copyWith(
                        inactiveDays:
                            currentFilter.inactiveDays == _inactivePreset
                                ? null
                                : _inactivePreset,
                      ));
                    },
                  ),
                  const SizedBox(width: 6),
                  _QuickPill(
                    label: switch (currentFilter.sort) {
                      ClientSort.activity => 'Tri : activité',
                      ClientSort.recent => 'Tri : récents',
                      ClientSort.oldest => 'Tri : anciens',
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
                                onSms: () => context.push('/merchant/sms'),
                              );
                            },
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
                  const Icon(
                    LucideIcons.users,
                    size: 36,
                    color: AppColors.gray300,
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

// ── Bouton « Filtres » avec badge ────────────────────────────────────────

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
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
              size: 16,
              color:
                  activeCount > 0 ? AppColors.primary : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'Filtres',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: activeCount > 0
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    fontSize: 10.5,
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

// ── Pills rapides ────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : AppColors.border,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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

// ── Bottom sheet de filtres ──────────────────────────────────────────────

class _ClientsFilterSheet extends StatefulWidget {
  const _ClientsFilterSheet({required this.initial});

  final ClientsFilter initial;

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
                    style: const TextStyle(fontSize: 13),
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
                  for (final level in LoyaltyLevel.values)
                    _LevelChip(
                      level: level,
                      isSelected: _levelKey == level.key,
                      onTap: () => setState(() {
                        _levelKey = _levelKey == level.key ? null : level.key;
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
          color: isSelected ? AppColors.primaryTint : AppColors.background,
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

/// Chip de niveau : icône + couleur du niveau — le même visuel que celui
/// affiché au client dans son portefeuille.
class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  final LoyaltyLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? level.background : AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? level.color : AppColors.border,
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(level.icon, size: 14, color: level.color),
            const SizedBox(width: 5),
            Text(
              level.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? level.color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte client ─────────────────────────────────────────────────────────

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

    final level = LoyaltyLevel.fromKey(client.levelKey);

    final progressFactor =
        (client.stampsCount / stampsRequired).clamp(0.0, 1.0);

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
                // Initials Circle
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

                // Name & Info
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
                          const SizedBox(width: 6),
                          _LevelBadge(level: level),
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

                // Action Icons (View & SMS)
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
            const SizedBox(height: 10),

            // Progress Bar & Counter
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 4,
                      color: AppColors.border,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressFactor,
                        child: Container(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${client.stampsCount}/$stampsRequired',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

/// Badge de niveau : icône + libellé sur fond teinté de la couleur du
/// niveau — même identité visuelle que l'app client (symboles), mais
/// lisible pour le marchand grâce au libellé FR.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final LoyaltyLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: level.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: 10, color: level.color),
          const SizedBox(width: 2),
          Text(
            level.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: level.color,
            ),
          ),
        ],
      ),
    );
  }
}
