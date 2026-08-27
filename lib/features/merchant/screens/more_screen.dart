import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/core/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../models/restaurant_account.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/team_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/22890123456?text=Bonjour%20Miva-Fid,%20j\'ai%20besoin%20d\'aide.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: t.merchantSignOutConfirmTitle,
      message: t.merchantSignOutConfirmMessage,
      confirmLabel: t.merchantSignOutConfirm,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(merchantAuthProvider.notifier).signOut();
    if (context.mounted) context.go('/auth/merchant/auth');
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Supprimer votre compte ?',
      message:
          'Votre commerce, votre programme de fidélité et l\'accès de toute votre équipe seront désactivés. Cette action est définitive.',
      confirmLabel: 'Continuer',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;

    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Confirmer avec votre mot de passe'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: passwordCtrl,
              obscureText: true,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Mot de passe actuel'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Mot de passe requis.' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626)),
              onPressed: submitting
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => submitting = true);
                      try {
                        await ref
                            .read(merchantAuthProvider.notifier)
                            .deleteAccount(passwordCtrl.text);
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } on ValidationException catch (e) {
                        setDialogState(() => submitting = false);
                        if (ctx.mounted) ToastService.showError(e.message);
                      } catch (_) {
                        setDialogState(() => submitting = false);
                        if (ctx.mounted) {
                          ToastService.showError(
                              'Impossible de supprimer le compte. Réessayez.');
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Supprimer définitivement'),
            ),
          ],
        ),
      ),
    );

    if (done == true && context.mounted) {
      ToastService.showInfo('Compte supprimé.');
      context.go('/auth/merchant/auth');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final account = ref.watch(merchantAuthProvider.select((s) => s.restaurant));
    final teamAsync = ref.watch(teamNotifierProvider);

    final merchantName =
        (account?.name?.isNotEmpty ?? false) ? account!.name! : 'Votre Commerce';
    final category = (account?.category?.isNotEmpty ?? false)
        ? account!.category!
        : 'Commerce';
    final city = (account?.city?.isNotEmpty ?? false)
        ? account!.city!
        : ((account?.address?.isNotEmpty ?? false) ? account!.address! : '');
    final logoUrl = account?.logoUrl;
    final initials = _initials(merchantName);

    final completion = _profileCompletion(context, account);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP HEADER ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.settings,
                      color: Color(0xFF5B50EC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.settingsTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/merchant/more/notifications'),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
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
                          top: 8,
                          right: 8,
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
              const SizedBox(height: 16),

              // ── 1. PROFIL DU COMMERCE CARD ──────────────────────────────
              InkWell(
                onTap: () => context.push('/merchant/more/profile'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          shape: BoxShape.circle,
                          image: (logoUrl != null && logoUrl.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(logoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (logoUrl == null || logoUrl.isEmpty)
                            ? Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF5B50EC),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchantName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              city.isNotEmpty ? '$category • $city' : category,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── 2. COMPLÉTER MON PROFIL CARD ────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.merchantMoreCompleteProfile,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${completion.done}/${completion.total}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 5,
                        width: double.infinity,
                        color: AppColors.border,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: completion.ratio,
                          child: Container(color: const Color(0xFF5B50EC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...completion.tasks.asMap().entries.map((entry) {
                      final i = entry.key;
                      final task = entry.value;
                      return Column(
                        children: [
                          if (i > 0)
                            Divider(height: 16, color: AppColors.border),
                          _buildTaskRow(
                            title: task.label,
                            done: task.done,
                            onTap: task.onTap,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 3. SECTION COMPTE ────────────────────────────────────────
              _buildSectionLabel(t.merchantMoreSectionAccount),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.user,
                  label: t.merchantMoreBusinessProfile,
                  onTap: () => context.push('/merchant/more/profile'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.clock,
                  label: t.merchantMoreHours,
                  tag: completion.hoursDone ? 'Configuré' : null,
                  tagDone: completion.hoursDone,
                  onTap: () => context.push('/merchant/more/hours'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.link,
                  label: t.merchantMoreSocials,
                  tag: completion.socialsDone ? 'Configuré' : t.merchantMoreToComplete,
                  tagDone: completion.socialsDone,
                  onTap: () => context.push('/merchant/more/socials'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.creditCard,
                  label: t.merchantMoreSubscription,
                  tag: t.merchantMoreProTag,
                  onTap: () => context.push('/merchant/more/subscription'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.sliders,
                  label: t.settingsPreferences,
                  onTap: () => context.push('/merchant/more/preferences'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.globe,
                  label: t.merchantMoreLanguageTheme,
                  tag: locale.languageCode == 'en'
                      ? t.settingsLanguageEnglish
                      : t.settingsLanguageFrench,
                  onTap: () => context.push('/merchant/more/language'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.users,
                  label: t.merchantMoreTeam,
                  tag: teamAsync.value?.length.toString(),
                  onTap: () => context.push('/merchant/more/team'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.lock,
                  label: 'Changer le mot de passe',
                  onTap: () => context.push('/merchant/more/change-password'),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 4. SECTION MA CARTE DE FIDÉLITÉ ──────────────────────────
              _buildSectionLabel(t.merchantMoreSectionLoyaltyCard),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.award,
                  label: 'Options du programme',
                  onTap: () => context.push('/merchant/more/programme'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.creditCard,
                  label: t.merchantMoreCustomizeCard,
                  onTap: () => context.push('/merchant/more/programme/design'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.gift,
                  label: t.merchantMoreGoalReward,
                  onTap: () => context.push('/merchant/more/programme/tiers'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.sparkles,
                  label: t.merchantMoreLoyaltyProgram,
                  onTap: () => context.push('/merchant/more/programme/rules'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.qrCode,
                  label: t.merchantMoreMyQrCode,
                  onTap: () => context.push('/merchant/more/account/qrcode'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.globe,
                  label: t.merchantMoreMyShowcase,
                  onTap: () => context.push('/merchant/more/account/vitrine'),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 5. SECTION ASSISTANCE ────────────────────────────────────
              _buildSectionLabel(t.merchantMoreSectionSupport),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.shieldCheck,
                  label: t.merchantMoreLegalPrivacy,
                  onTap: () => context.push('/client/legal/privacy'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.fileText,
                  label: t.merchantMoreLegalTerms,
                  onTap: () => context.push('/client/legal/terms'),
                ),
                _buildMenuItem(
                  icon: LucideIcons.messageCircle,
                  label: t.merchantMoreWhatsappSupport,
                  onTap: _launchWhatsApp,
                ),
              ]),
              const SizedBox(height: 20),

              // ── 6. ZONE DANGEREUX ────────────────────────────────────────
              _buildSectionLabel('ZONE DANGEREUSE'),
              const SizedBox(height: 8),
              _buildGroupCard([
                _buildMenuItem(
                  icon: LucideIcons.trash2,
                  label: 'Supprimer mon compte',
                  danger: true,
                  onTap: () => _deleteAccount(context, ref),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 7. SE DÉCONNECTER BUTTON ─────────────────────────────────
              InkWell(
                onTap: () => _signOut(context, ref),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dangerTint),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Text(
                        t.settingsSignOut,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 7. FOOTER ────────────────────────────────────────────────
              Center(
                child: Text(
                  'Miva-Fid v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  _ProfileCompletion _profileCompletion(
    BuildContext context,
    RestaurantAccount? account,
  ) {
    final hoursDone = account?.hasOpeningHours ?? false;
    final socialsDone = account?.hasSocials ?? false;

    final tasks = [
      _CompletionTask(
        label: 'Logo du commerce',
        done: (account?.logoUrl?.isNotEmpty ?? false),
        onTap: () => context.push('/merchant/more/profile'),
      ),
      _CompletionTask(
        label: 'Description du commerce',
        done: (account?.description?.isNotEmpty ?? false),
        onTap: () => context.push('/merchant/more/profile'),
      ),
      _CompletionTask(
        label: "Horaires d'ouverture",
        done: hoursDone,
        onTap: () => context.push('/merchant/more/hours'),
      ),
      _CompletionTask(
        label: 'Réseaux sociaux',
        done: socialsDone,
        onTap: () => context.push('/merchant/more/socials'),
      ),
    ];

    return _ProfileCompletion(
      tasks: tasks,
      total: tasks.length,
      hoursDone: hoursDone,
      socialsDone: socialsDone,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              item,
              if (idx < children.length - 1)
                Divider(height: 1, indent: 48, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskRow({
    required String title,
    required bool done,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          done
              ? const Icon(LucideIcons.circleCheck,
                  size: 20, color: Color(0xFF10B981))
              : Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textSecondary,
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: done ? AppColors.textSecondary : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Icon(
            done ? LucideIcons.check : LucideIcons.chevronRight,
            size: 16,
            color: done ? const Color(0xFF10B981) : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    String? tag,
    bool tagDone = false,
    bool danger = false,
    required VoidCallback onTap,
  }) {
    final labelColor = danger ? const Color(0xFFDC2626) : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: danger ? const Color(0xFFDC2626) : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            if (tag != null) ...[
              Text(
                tag,
                style: TextStyle(
                  fontSize: 12.5,
                  color: tagDone ? const Color(0xFF10B981) : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionTask {
  const _CompletionTask({
    required this.label,
    required this.done,
    required this.onTap,
  });

  final String label;
  final bool done;
  final VoidCallback onTap;
}

class _ProfileCompletion {
  const _ProfileCompletion({
    required this.tasks,
    required this.total,
    required this.hoursDone,
    required this.socialsDone,
  });

  final List<_CompletionTask> tasks;
  final int total;
  final bool hoursDone;
  final bool socialsDone;

  int get done => tasks.where((t) => t.done).length;

  double get ratio => total == 0 ? 0 : done / total;
}
