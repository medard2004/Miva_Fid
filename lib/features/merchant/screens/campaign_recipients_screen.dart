import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/campaign_model.dart';
import '../providers/sms_campaign_draft_provider.dart';

const _segments = [
  ('all', 'Tous', LucideIcons.users),
  ('inactive', 'Inactifs', LucideIcons.userX),
  ('near_reward', 'Proches récompense', LucideIcons.gift),
  ('reward_available', 'Récompense dispo', LucideIcons.trophy),
];

const _sorts = [
  ('activity', 'Plus actifs'),
  ('recent', 'Plus récents'),
  ('oldest', 'Plus anciens'),
];

/// Étape 3 du wizard : sélection de l'audience cible.
class CampaignRecipientsScreen extends ConsumerStatefulWidget {
  const CampaignRecipientsScreen({super.key, this.editingCampaign});

  final CampaignModel? editingCampaign;

  @override
  ConsumerState<CampaignRecipientsScreen> createState() =>
      _CampaignRecipientsScreenState();
}

class _CampaignRecipientsScreenState
    extends ConsumerState<CampaignRecipientsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(campaignDraftProvider(widget.editingCampaign));
    final notifier =
        ref.read(campaignDraftProvider(widget.editingCampaign).notifier);
    final selectedCount = draft.selectedClientIds.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Destinataires',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save, size: 20),
            tooltip: 'Sauvegarder en brouillon',
            onPressed: () async {
              try {
                await notifier.saveAsDraft(3);
                if (context.mounted) {
                  ToastService.showSuccess('Brouillon sauvegardé');
                  context.go('/merchant/sms');
                }
              } catch (e) {
                if (context.mounted) ToastService.showError('$e');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= 2
                              ? const Color(0xFF5B50EC)
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Segment chips
            if (draft.type != CampaignType.reward)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _segments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final (type, label, icon) = _segments[i];
                      final active = draft.recipientType == type;
                      return ChoiceChip(
                        avatar: Icon(icon, size: 14,
                            color: active ? Colors.white : AppColors.textSecondary),
                        label: Text(label),
                        selected: active,
                        onSelected: (_) => notifier.setSegment(type),
                        selectedColor: const Color(0xFF5B50EC),
                        labelStyle: TextStyle(
                          color: active ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.border),
                      );
                    },
                  ),
                ),
              ),

            // Search + sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: notifier.setSearch,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Rechercher nom ou téléphone',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    initialValue: draft.sort,
                    onSelected: notifier.setSort,
                    itemBuilder: (_) => _sorts
                        .map((s) =>
                            PopupMenuItem(value: s.$1, child: Text(s.$2)))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(LucideIcons.arrowUpDown, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Select all / count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: draft.visibleRecipients.isEmpty
                        ? null
                        : notifier.toggleSelectAllVisible,
                    icon: Icon(
                      draft.allVisibleSelected
                          ? LucideIcons.squareCheck
                          : LucideIcons.square,
                      size: 17,
                    ),
                    label: Text(
                      draft.allVisibleSelected
                          ? 'Tout décocher'
                          : 'Tout cocher',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$selectedCount sélectionné${selectedCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 12),

            // Recipients list
            Expanded(
              child: draft.loadingRecipients
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF5B50EC)))
                  : draft.visibleRecipients.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun client trouvé',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: draft.visibleRecipients.length,
                          itemBuilder: (_, i) {
                            final r = draft.visibleRecipients[i];
                            final checked = draft.selectedClientIds
                                .contains(r.clientId);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (_) =>
                                  notifier.toggle(r.clientId),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              title: Text(
                                r.name.isEmpty
                                    ? 'Client #${r.clientId}'
                                    : r.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5),
                              ),
                              subtitle: Text(
                                [
                                  if (r.phone != null &&
                                      r.phone!.isNotEmpty)
                                    r.phone!,
                                  r.lastActivityAt != null
                                      ? 'Actif ${DateFormatter.relative(r.lastActivityAt!)}'
                                      : 'Jamais actif',
                                ].join(' • '),
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary),
                              ),
                            );
                          },
                        ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedCount == 0
                        ? null
                        : () => context.push(
                              '/merchant/campaigns/new/summary',
                              extra: widget.editingCampaign,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B50EC),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Suivant — $selectedCount destinataire${selectedCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
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
}
