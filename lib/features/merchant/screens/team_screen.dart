import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_translator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../models/team_member.dart';
import '../providers/team_provider.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  void _showInviteSheet(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role = 'operator';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: Sp.md, right: Sp.md, top: Sp.md,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + Sp.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.merchantTeamInviteTitle, style: AppTextStyles.h3()),
              const SizedBox(height: Sp.md),
              AppInput(label: t.merchantTeamNameLabel, controller: nameCtrl, accentColor: AppColors.merchant),
              const SizedBox(height: Sp.sm),
              AppInput(label: t.editProfileEmail, controller: emailCtrl, keyboardType: TextInputType.emailAddress, accentColor: AppColors.merchant),
              const SizedBox(height: Sp.sm),
              AppInput(label: t.merchantTeamPhoneOptionalLabel, controller: phoneCtrl, keyboardType: TextInputType.phone, accentColor: AppColors.merchant),
              const SizedBox(height: Sp.sm),
              AppInput(label: t.merchantTeamPasswordLabel, controller: passwordCtrl, obscureText: true, accentColor: AppColors.merchant),
              const SizedBox(height: Sp.sm),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t.merchantTeamRoleOperator),
                      selected: role == 'operator',
                      onSelected: (_) => setSheetState(() => role = 'operator'),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t.merchantTeamRoleAdmin),
                      selected: role == 'admin',
                      onSelected: (_) => setSheetState(() => role = 'admin'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),
              AppButton.merchant(
                t.merchantTeamInviteButton,
                loading: saving,
                onPressed: () async {
                  setSheetState(() => saving = true);
                  final notifier = ref.read(teamNotifierProvider.notifier);
                  final ok = await notifier.invite(
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        password: passwordCtrl.text,
                        role: role,
                      );
                  if (!sheetContext.mounted) return;
                  if (ok) {
                    Navigator.pop(sheetContext);
                  } else {
                    setSheetState(() => saving = false);
                    // Le motif réel (ex. e-mail déjà utilisé) vient du
                    // backend via `lastError` : un message générique ici
                    // masquerait la cause à l'administrateur.
                    final message = ErrorTranslator.translate(
                      notifier.lastError,
                      context: ErrorContext.manageTeam,
                    ).displayMessage ??
                        t.merchantTeamInviteError;
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final teamAsync = ref.watch(teamNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.merchantMoreTeam),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            onPressed: () => _showInviteSheet(context, ref),
          ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            ErrorTranslator.translate(e, context: ErrorContext.manageTeam)
                    .displayMessage ??
                t.errUnexpected,
            style: AppTextStyles.bodyMd(),
            textAlign: TextAlign.center,
          ),
        ),
        data: (team) => team.isEmpty
            ? Center(
                child: Text(
                  t.merchantTeamEmptyState,
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(Sp.md),
                itemCount: team.length,
                separatorBuilder: (_, __) => const SizedBox(height: Sp.sm),
                itemBuilder: (context, i) => _TeamMemberTile(member: team[i]),
              ),
      ),
    );
  }
}

class _TeamMemberTile extends ConsumerWidget {
  final TeamMember member;
  const _TeamMemberTile({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: AppTextStyles.labelBold()),
                Text(member.email, style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
                Text(
                  member.role == 'admin' ? t.merchantTeamRoleAdmin : t.merchantTeamRoleOperator,
                  style: AppTextStyles.caption().copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Switch(
            value: member.isActive,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.merchant,
            onChanged: (val) async {
              final notifier = ref.read(teamNotifierProvider.notifier);
              final ok = await notifier.toggleActive(member.id, val);
              if (!ok && context.mounted) {
                final message = ErrorTranslator.translate(
                  notifier.lastError,
                  context: ErrorContext.manageTeam,
                ).displayMessage ??
                    t.merchantTeamToggleStatusError;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
