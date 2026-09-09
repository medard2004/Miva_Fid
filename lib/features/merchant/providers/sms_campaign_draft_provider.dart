import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/campaign_model.dart';
import '../../../models/campaign_recipient_model.dart';
import 'sms_provider.dart';

/// Types de campagne supportés par le wizard.
enum CampaignType {
  promotion('promotion', 'Promotion / Annonce', '🏷️'),
  reminder('reminder', 'Rappel d\'inactivité', '🔔'),
  review('review', 'Notation / Avis', '⭐'),
  reward('reward', 'Récompense', '🎁'),
  progress('progress', 'Progression fidélité', '📈'),
  referral('referral', 'Parrainage', '🤝');

  const CampaignType(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;

  /// Indique si ce type nécessite un champ image.
  bool get hasImage => this == promotion;

  /// Indique si ce type nécessite un titre.
  bool get hasTitle => true;

  /// Indique si ce type nécessite un message/description.
  bool get hasMessage => true;

  static CampaignType fromValue(String value) =>
      CampaignType.values.firstWhere((t) => t.value == value,
          orElse: () => CampaignType.promotion);
}

/// Brouillon de campagne partagé entre les étapes du wizard.
/// Vit le temps du wizard : recréé à chaque ouverture, jamais persisté.
class CampaignDraft {
  const CampaignDraft({
    this.type,
    this.title = '',
    this.message = '',
    this.imageUrl,
    this.localImagePath,
    this.recipientType = 'all',
    this.visibleRecipients = const [],
    this.selectedClientIds = const {},
    this.manuallyEdited = false,
    this.search = '',
    this.sort = 'activity',
    this.loadingRecipients = false,
    this.scheduledAt,
    this.sending = false,
  });

  final CampaignType? type;
  final String title;
  final String message;
  final String? imageUrl;
  final String? localImagePath;
  final String recipientType;
  final List<CampaignRecipientModel> visibleRecipients;
  final Set<int> selectedClientIds;

  /// Vrai dès que la sélection s'écarte d'un segment propre unique.
  final bool manuallyEdited;
  final String search;
  final String sort;
  final bool loadingRecipients;
  final DateTime? scheduledAt;
  final bool sending;

  /// Étiquette réellement envoyée au serveur.
  String get effectiveRecipientType => manuallyEdited ? 'manual' : recipientType;

  bool get allVisibleSelected =>
      visibleRecipients.isNotEmpty &&
      visibleRecipients.every((r) => selectedClientIds.contains(r.clientId));

  CampaignDraft copyWith({
    CampaignType? Function()? type,
    String? title,
    String? message,
    String? Function()? imageUrl,
    String? Function()? localImagePath,
    String? recipientType,
    List<CampaignRecipientModel>? visibleRecipients,
    Set<int>? selectedClientIds,
    bool? manuallyEdited,
    String? search,
    String? sort,
    bool? loadingRecipients,
    DateTime? Function()? scheduledAt,
    bool? sending,
  }) {
    return CampaignDraft(
      type: type != null ? type() : this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
      localImagePath: localImagePath != null ? localImagePath() : this.localImagePath,
      recipientType: recipientType ?? this.recipientType,
      visibleRecipients: visibleRecipients ?? this.visibleRecipients,
      selectedClientIds: selectedClientIds ?? this.selectedClientIds,
      manuallyEdited: manuallyEdited ?? this.manuallyEdited,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      loadingRecipients: loadingRecipients ?? this.loadingRecipients,
      scheduledAt: scheduledAt != null ? scheduledAt() : this.scheduledAt,
      sending: sending ?? this.sending,
    );
  }
}

class CampaignDraftNotifier extends StateNotifier<CampaignDraft> {
  /// [editingCampaign] non nul : édite cette campagne (encore programmée)
  /// au lieu d'en créer une nouvelle.
  CampaignDraftNotifier(this._ref, this.editingCampaign)
      : super(
          editingCampaign == null
              ? const CampaignDraft()
              : CampaignDraft(
                  type: CampaignType.fromValue(editingCampaign.type),
                  title: editingCampaign.title,
                  message: editingCampaign.message,
                  imageUrl: editingCampaign.imageUrl,
                  scheduledAt: editingCampaign.scheduledAt,
                  manuallyEdited: true,
                ),
        ) {
    _pendingInitialSelection = editingCampaign?.recipientIds
        ?.map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();
    final initialRecipientType = editingCampaign?.recipientType ??
        (editingCampaign?.type == 'reward' ? 'reward_available' : 'all');
    setSegment(initialRecipientType);
  }

  final Ref _ref;
  final CampaignModel? editingCampaign;
  Set<int>? _pendingInitialSelection;

  // ── Step 1: Type ──────────────────────────────────────────────────────
  void setType(CampaignType type) {
    state = state.copyWith(
      type: () => type,
      recipientType: type == CampaignType.reward ? 'reward_available' : 'all',
      selectedClientIds: {},
      manuallyEdited: false,
    );
    _reload();
  }

  // ── Step 2: Content ───────────────────────────────────────────────────
  void setTitle(String title) => state = state.copyWith(title: title);
  void setMessage(String message) => state = state.copyWith(message: message);
  void setImageUrl(String? url) =>
      state = state.copyWith(imageUrl: () => url);
  void setLocalImagePath(String? path) =>
      state = state.copyWith(localImagePath: () => path);

  // ── Step 3: Recipients ────────────────────────────────────────────────
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

  // ── Step 4: Schedule ──────────────────────────────────────────────────
  void setScheduledAt(DateTime? date) =>
      state = state.copyWith(scheduledAt: () => date);

  Future<void> saveAsDraft(int step) async {
    state = state.copyWith(sending: true);
    try {
      final campaign = editingCampaign;
      final type = state.type?.value ?? 'promotion';
      
      await _ref.read(smsNotifierProvider.notifier).saveDraft(
            campaignId: campaign?.id,
            type: type,
            title: state.title.trim().isEmpty ? null : state.title.trim(),
            message: state.message.trim().isEmpty ? null : state.message.trim(),
            imageUrl: state.imageUrl,
            localImagePath: state.localImagePath,
            recipientType: state.effectiveRecipientType,
            clientIds: state.selectedClientIds.toList(),
            scheduledAt: state.scheduledAt,
            draftStep: step,
          );
    } finally {
      if (mounted) state = state.copyWith(sending: false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────
  Future<void> submit() async {
    state = state.copyWith(sending: true);
    try {
      final campaign = editingCampaign;
      final type = state.type?.value ?? 'promotion';
      if (campaign != null) {
        final scheduledAt = state.scheduledAt;
        if (scheduledAt == null && campaign.status != 'draft') {
          throw Exception('Une date de programmation est requise pour modifier cette campagne.');
        }
        await _ref.read(smsNotifierProvider.notifier).updateCampaign(
              campaignId: campaign.id,
              type: type,
              title: state.title.trim().isEmpty ? null : state.title.trim(),
              message: state.message.trim().isEmpty ? null : state.message.trim(),
              imageUrl: state.imageUrl,
              localImagePath: state.localImagePath,
              recipientType: state.effectiveRecipientType,
              clientIds: state.selectedClientIds.toList(),
              scheduledAt: scheduledAt,
            );
      } else {
        await _ref.read(smsNotifierProvider.notifier).sendCampaign(
              type: type,
              title: state.title.trim().isEmpty ? null : state.title.trim(),
              message: state.message.trim().isEmpty ? null : state.message.trim(),
              imageUrl: state.imageUrl,
              localImagePath: state.localImagePath,
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

final campaignDraftProvider = StateNotifierProvider.autoDispose
    .family<CampaignDraftNotifier, CampaignDraft, CampaignModel?>(
  (ref, editingCampaign) => CampaignDraftNotifier(ref, editingCampaign),
);

// Alias pour compatibilité arrière
final smsCampaignDraftProvider = campaignDraftProvider;
