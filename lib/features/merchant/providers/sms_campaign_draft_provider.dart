import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/campaign_recipient_model.dart';
import '../../../models/sms_campaign_model.dart';
import 'sms_provider.dart';

/// Brouillon de campagne SMS partagé entre les 2 pages du wizard
/// ("Destinataires" puis "Message"). Vit le temps du wizard : recréé à
/// chaque ouverture, jamais persisté.
class SmsCampaignDraft {
  const SmsCampaignDraft({
    this.recipientType = 'all',
    this.visibleRecipients = const [],
    this.selectedClientIds = const {},
    this.manuallyEdited = false,
    this.search = '',
    this.sort = 'activity',
    this.loadingRecipients = false,
    this.message = '',
    this.scheduledAt,
    this.sending = false,
  });

  final String recipientType;
  final List<CampaignRecipientModel> visibleRecipients;
  final Set<int> selectedClientIds;

  /// Vrai dès que la sélection s'écarte d'un segment propre unique (coche
  /// individuelle décochée, ou cumul de plusieurs segments — ou édition
  /// d'une campagne existante) — le `recipient_type` envoyé au serveur
  /// devient alors `'manual'`.
  final bool manuallyEdited;
  final String search;
  final String sort;
  final bool loadingRecipients;
  final String message;
  final DateTime? scheduledAt;
  final bool sending;

  /// Étiquette réellement envoyée au serveur (juste informatif, les
  /// destinataires effectifs sont toujours `selectedClientIds`).
  String get effectiveRecipientType => manuallyEdited ? 'manual' : recipientType;

  bool get allVisibleSelected =>
      visibleRecipients.isNotEmpty &&
      visibleRecipients.every((r) => selectedClientIds.contains(r.clientId));

  SmsCampaignDraft copyWith({
    String? recipientType,
    List<CampaignRecipientModel>? visibleRecipients,
    Set<int>? selectedClientIds,
    bool? manuallyEdited,
    String? search,
    String? sort,
    bool? loadingRecipients,
    String? message,
    DateTime? Function()? scheduledAt,
    bool? sending,
  }) {
    return SmsCampaignDraft(
      recipientType: recipientType ?? this.recipientType,
      visibleRecipients: visibleRecipients ?? this.visibleRecipients,
      selectedClientIds: selectedClientIds ?? this.selectedClientIds,
      manuallyEdited: manuallyEdited ?? this.manuallyEdited,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      loadingRecipients: loadingRecipients ?? this.loadingRecipients,
      message: message ?? this.message,
      scheduledAt: scheduledAt != null ? scheduledAt() : this.scheduledAt,
      sending: sending ?? this.sending,
    );
  }
}

class SmsCampaignDraftNotifier extends StateNotifier<SmsCampaignDraft> {
  /// [editingCampaign] non nul : édite cette campagne (encore programmée)
  /// au lieu d'en créer une nouvelle — préremplit message/date/destinataires
  /// et appelle `updateCampaign` plutôt que `sendCampaign` à la soumission.
  SmsCampaignDraftNotifier(this._ref, this.editingCampaign)
      : super(
          editingCampaign == null
              ? const SmsCampaignDraft()
              : SmsCampaignDraft(
                  message: editingCampaign.message,
                  scheduledAt: editingCampaign.scheduledAt,
                  manuallyEdited: true,
                ),
        ) {
    // La toute première liste chargée sert juste à rendre la base cliente
    // parcourable (recherche/segments) — en édition, la présélection ne
    // doit PAS venir du segment "Tous" mais de la sélection déjà en base.
    _pendingInitialSelection = editingCampaign?.recipientIds
        ?.map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();
    setSegment('all');
  }

  final Ref _ref;
  final SmsCampaignModel? editingCampaign;
  Set<int>? _pendingInitialSelection;

  Future<void> setSegment(String type) async {
    final hadOtherSelection =
        state.selectedClientIds.isNotEmpty && state.recipientType != type;
    state = state.copyWith(
      recipientType: type,
      loadingRecipients: true,
      manuallyEdited: hadOtherSelection ? true : null,
    );
    await _reload();
  }

  Future<void> setSearch(String q) async {
    state = state.copyWith(search: q, loadingRecipients: true);
    await _reload();
  }

  Future<void> setSort(String sort) async {
    state = state.copyWith(sort: sort, loadingRecipients: true);
    await _reload();
  }

  Future<void> _reload() async {
    try {
      final list = await _ref.read(smsNotifierProvider.notifier).fetchRecipients(
            recipientType: state.recipientType,
            q: state.search,
            sort: state.sort,
          );
      final pending = _pendingInitialSelection;
      // Un changement de segment présélectionne (coche) tout son résultat,
      // sans jamais décocher ce qui a déjà été choisi ailleurs — sauf le
      // tout premier chargement en mode édition, où la sélection initiale
      // vient de la campagne existante, pas du segment "Tous".
      final selected = pending ?? {...state.selectedClientIds, ...list.map((r) => r.clientId)};
      _pendingInitialSelection = null;
      state = state.copyWith(
        visibleRecipients: list,
        selectedClientIds: selected,
        loadingRecipients: false,
      );
    } catch (_) {
      state = state.copyWith(loadingRecipients: false);
    }
  }

  void toggle(int clientId) {
    final next = {...state.selectedClientIds};
    if (!next.remove(clientId)) next.add(clientId);
    state = state.copyWith(selectedClientIds: next, manuallyEdited: true);
  }

  /// Coche/décoche uniquement les lignes actuellement affichées (respecte
  /// une éventuelle recherche/segment en cours).
  void toggleSelectAllVisible() {
    final next = {...state.selectedClientIds};
    if (state.allVisibleSelected) {
      for (final r in state.visibleRecipients) {
        next.remove(r.clientId);
      }
    } else {
      for (final r in state.visibleRecipients) {
        next.add(r.clientId);
      }
    }
    state = state.copyWith(selectedClientIds: next, manuallyEdited: true);
  }

  void setMessage(String message) => state = state.copyWith(message: message);

  void setScheduledAt(DateTime? date) =>
      state = state.copyWith(scheduledAt: () => date);

  Future<void> submit() async {
    state = state.copyWith(sending: true);
    try {
      final campaign = editingCampaign;
      if (campaign != null) {
        final scheduledAt = state.scheduledAt;
        if (scheduledAt == null) {
          throw Exception('Une date de programmation est requise pour modifier cette campagne.');
        }
        await _ref.read(smsNotifierProvider.notifier).updateCampaign(
              campaignId: campaign.id,
              message: state.message.trim(),
              recipientType: state.effectiveRecipientType,
              clientIds: state.selectedClientIds.toList(),
              scheduledAt: scheduledAt,
            );
      } else {
        await _ref.read(smsNotifierProvider.notifier).sendCampaign(
              message: state.message.trim(),
              recipientType: state.effectiveRecipientType,
              clientIds: state.selectedClientIds.toList(),
              scheduledAt: state.scheduledAt,
            );
      }
    } finally {
      if (mounted) state = state.copyWith(sending: false);
    }
  }
}

final smsCampaignDraftProvider = StateNotifierProvider.autoDispose
    .family<SmsCampaignDraftNotifier, SmsCampaignDraft, SmsCampaignModel?>(
  (ref, editingCampaign) => SmsCampaignDraftNotifier(ref, editingCampaign),
);
