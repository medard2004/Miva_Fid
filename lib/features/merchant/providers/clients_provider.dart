import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/api_providers.dart';
import '../../../models/loyalty_card_model.dart';
import 'dashboard_stats_provider.dart' show dashboardStatsProvider;
import 'merchant_auth_provider.dart';

part 'clients_provider.g.dart';

/// Tri de la liste clients — correspond aux valeurs du paramètre
/// `sort` de `GET /merchant/clients`.
enum ClientSort {
  /// Activité récente d'abord (défaut côté API).
  activity('activity'),

  /// Clients inscrits le plus récemment.
  recent('recent'),

  /// Clients inscrits en premier.
  oldest('oldest');

  const ClientSort(this.apiValue);
  final String apiValue;
}

/// Filtres structurés de la liste clients — tous résolus côté serveur,
/// plus aucun matching local sur les libellés de niveau.
class ClientsFilter {
  const ClientsFilter({
    this.search = '',
    this.inactiveDays,
    this.levelKey,
    this.minCycles,
    this.sort = ClientSort.activity,
  });

  final String search;
  final int? inactiveDays;
  final String? levelKey;
  final int? minCycles;
  final ClientSort sort;

  bool get hasActiveFilters =>
      inactiveDays != null || levelKey != null || minCycles != null;

  int get activeFilterCount =>
      [inactiveDays, levelKey, minCycles].where((v) => v != null).length;

  /// État par défaut (filtres et tri réinitialisés, recherche conservée
  /// ou non selon [keepSearch]).
  ClientsFilter reset({bool keepSearch = false}) => ClientsFilter(
        search: keepSearch ? search : '',
      );

  ClientsFilter copyWith({
    String? search,
    Object? inactiveDays = _unset,
    Object? levelKey = _unset,
    Object? minCycles = _unset,
    ClientSort? sort,
  }) =>
      ClientsFilter(
        search: search ?? this.search,
        inactiveDays:
            inactiveDays == _unset ? this.inactiveDays : inactiveDays as int?,
        levelKey: levelKey == _unset ? this.levelKey : levelKey as String?,
        minCycles: minCycles == _unset ? this.minCycles : minCycles as int?,
        sort: sort ?? this.sort,
      );

  static const _unset = Object();
}

/// État rendu par [ClientsNotifier] : page 1 + pages accumulées par le
/// scroll infini ([loadMore]), avec le total serveur pour l'affichage.
class ClientsListState {
  const ClientsListState({
    required this.clients,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    this.isLoadingMore = false,
  });

  final List<LoyaltyCardModel> clients;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;

  bool get hasMore => currentPage < lastPage;

  ClientsListState copyWith({
    List<LoyaltyCardModel>? clients,
    int? total,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
  }) =>
      ClientsListState(
        clients: clients ?? this.clients,
        total: total ?? this.total,
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// Clientèle du commerce connecté (`GET /merchant/clients`, paginé).
///
/// Recherche, inactivité, niveau (clé canonique) et cycles terminés sont
/// filtrés côté serveur ; chaque changement de filtre repart de la page 1.
@riverpod
class ClientsNotifier extends _$ClientsNotifier {
  ClientsFilter _filter = const ClientsFilter();
  Timer? _debounce;
  bool _isLoadingMore = false;

  /// Incrémenté à chaque invalidation demandée : un `loadMore` parti en
  /// vol avant un changement de filtre doit jeter sa réponse périmée.
  int _generation = 0;

  void _invalidate() {
    _generation++;
    ref.invalidateSelf();
  }

  /// Filtre actuellement appliqué — lu par l'UI pour surligner les pills
  /// et pré-remplir le bottom sheet (l'état se reconstruisant à chaque
  /// changement de filtre, la lecture dans `build()` reste fraîche).
  ClientsFilter get currentFilter => _filter;

  @override
  Future<ClientsListState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    final restaurant = ref.watch(
      merchantAuthProvider.select((s) => s.restaurant),
    );
    if (restaurant == null) {
      return const ClientsListState(
          clients: [], total: 0, currentPage: 1, lastPage: 1);
    }

    final page = await ref.read(merchantDashboardServiceProvider).clients(
          search: _filter.search.isEmpty ? null : _filter.search,
          inactiveDays: _filter.inactiveDays,
          levelKey: _filter.levelKey,
          minCycles: _filter.minCycles,
          sort: _filter.sort.apiValue,
        );
    return ClientsListState(
      clients: page.items.map(LoyaltyCardModel.fromJson).toList(),
      total: page.total,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
    );
  }

  /// Applique un filtre complet construit par l'UI (bottom sheet, pills).
  void applyFilter(ClientsFilter filter) {
    _debounce?.cancel();
    _filter = filter;
    _invalidate();
  }

  /// Recherche texte débouncée — appelée à chaque frappe, un seul appel
  /// API après 300 ms d'inactivité clavier.
  void search(String q) {
    _filter = _filter.copyWith(search: q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _invalidate();
    });
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    _invalidate();
    await future;
  }

  /// Scroll infini : charge la page suivante et l'accumule à l'état.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        _isLoadingMore) {
      return;
    }
    final gen = _generation;
    _isLoadingMore = true;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await ref.read(merchantDashboardServiceProvider).clients(
            search: _filter.search.isEmpty ? null : _filter.search,
            inactiveDays: _filter.inactiveDays,
            levelKey: _filter.levelKey,
            minCycles: _filter.minCycles,
            sort: _filter.sort.apiValue,
            page: current.currentPage + 1,
          );
      // Un filtre a changé pendant le fetch : la reconstruction déclenchée
      // par le filtre est la source de vérité, on jette cette page périmée.
      if (gen != _generation) return;
      final base = state.value ?? current;
      state = AsyncData(base.copyWith(
        clients: [
          ...base.clients,
          ...next.items.map(LoyaltyCardModel.fromJson),
        ],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        isLoadingMore: false,
      ));
    } on Exception catch (_) {
      // Échec silencieux du chargement suivant : la page déjà affichée
      // reste utilisable, l'utilisateur pourra re-scroller pour retenter.
      if (gen != _generation) return;
      final base = state.value ?? current;
      state = AsyncData(base.copyWith(isLoadingMore: false));
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Accorde un tampon depuis la fiche client.
  Future<void> addBonusStamp(String cardId) async {
    await ref.read(merchantDashboardServiceProvider).addStamp(cardId);
    ref.invalidate(dashboardStatsProvider);
    _invalidate();
  }

  /// Retire le dernier tampon accordé depuis la fiche client. Lève une
  /// [ApiException] (via le service) si le serveur refuse le retrait.
  Future<void> removeBonusStamp(String cardId) async {
    await ref.read(merchantDashboardServiceProvider).removeStamp(cardId);
    ref.invalidate(dashboardStatsProvider);
    _invalidate();
  }
}
