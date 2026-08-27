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
import '../../client/providers/settings_provider.dart';
import '../models/team_member.dart';
import '../providers/team_provider.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  void _showInviteSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Inviter un membre', style: AppTextStyles.h3()),
                const SizedBox(height: Sp.md),
                AppInput(label: 'Nom', controller: nameCtrl, accentColor: AppColors.merchant,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis.' : null),
                const SizedBox(height: Sp.sm),
                AppInput(label: 'Email', controller: emailCtrl, keyboardType: TextInputType.emailAddress, accentColor: AppColors.merchant,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return "L'email est requis.";
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                      return "Adresse e-mail invalide.";
                    }
                    return null;
                  }),
                const SizedBox(height: Sp.sm),
                AppInput(label: 'Téléphone (optionnel)', controller: phoneCtrl, keyboardType: TextInputType.phone, accentColor: AppColors.merchant),
                const SizedBox(height: Sp.sm),
                AppInput(label: 'Mot de passe', controller: passwordCtrl, obscureText: true, accentColor: AppColors.merchant,
                  validator: (v) =>
                      (v == null || v.length < 8) ? '8 caractères minimum.' : null),
                const SizedBox(height: Sp.sm),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Opérateur'),
                      selected: role == 'operator',
                      onSelected: (_) => setSheetState(() => role = 'operator'),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Administrateur'),
                      selected: role == 'admin',
                      onSelected: (_) => setSheetState(() => role = 'admin'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),
              AppButton.merchant(
                'Inviter',
                loading: saving,
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
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
                        'Impossible d\'inviter ce membre.';
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
      ),
    );
  }

  static void _showEditSheet(
      BuildContext context, WidgetRef ref, TeamMember member) {
    final nameCtrl = TextEditingController(text: member.name);
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String role = member.role;
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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Modifier le membre', style: AppTextStyles.h3()),
                const SizedBox(height: Sp.sm),
                Text(member.email,
                    style: AppTextStyles.caption()
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: Sp.md),
                AppInput(label: 'Nom', controller: nameCtrl, accentColor: AppColors.merchant,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis.' : null),
                const SizedBox(height: Sp.sm),
                Text('Rôle', style: AppTextStyles.caption()),
                const SizedBox(height: Sp.xs),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Opérateur'),
                        selected: role == 'operator',
                        onSelected: (_) => setSheetState(() => role = 'operator'),
                      ),
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Administrateur'),
                        selected: role == 'admin',
                        onSelected: (_) => setSheetState(() => role = 'admin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.md),
                AppInput(label: 'Nouveau mot de passe (optionnel)', controller: passwordCtrl,
                  obscureText: true, accentColor: AppColors.merchant,
                  validator: (v) =>
                      (v != null && v.isNotEmpty && v.length < 8)
                          ? '8 caractères minimum.'
                          : null),
                const SizedBox(height: Sp.md),
                AppButton.merchant(
                  'Enregistrer',
                  loading: saving,
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    setSheetState(() => saving = true);
                    final notifier = ref.read(teamNotifierProvider.notifier);
                    final ok = await notifier.updateMember(
                      member.id,
                      name: nameCtrl.text.trim(),
                      role: role,
                      password:
                          passwordCtrl.text.isEmpty ? null : passwordCtrl.text,
                    );
                    if (!sheetContext.mounted) return;
                    if (ok) {
                      Navigator.pop(sheetContext);
                    } else {
                      setSheetState(() => saving = false);
                      final message = ErrorTranslator.translate(
                        notifier.lastError,
                        context: ErrorContext.manageTeam,
                      ).displayMessage ??
                          'Impossible de modifier ce membre.';
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
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final teamAsync = ref.watch(teamNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Équipe'),
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
                'Une erreur est survenue. Réessayez.',
            style: AppTextStyles.bodyMd(),
            textAlign: TextAlign.center,
          ),
        ),
        data: (team) => team.isEmpty
            ? Center(
                child: Text(
                  'Aucun membre d\'équipe. Invitez votre premier opérateur.',
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
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  member.role == 'admin' ? 'Administrateur' : 'Opérateur',
                  style: AppTextStyles.caption().copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 16),
            color: AppColors.textSecondary,
            tooltip: 'Modifier',
            onPressed: () =>
                TeamScreen._showEditSheet(context, ref, member),
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
                    'Impossible de modifier le statut de ce membre.';
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
