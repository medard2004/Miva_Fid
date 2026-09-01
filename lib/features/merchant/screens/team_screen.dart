import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_translator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';
import '../models/team_member.dart';
import '../providers/team_provider.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  String _selectedRoleFilter = 'all'; // 'all', 'admin', 'operator'
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showInviteSheet(BuildContext context) {
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: Sp.md,
            right: Sp.md,
            top: 14,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + Sp.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
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
                    const SizedBox(width: 10),
                    Text(
                      t.merchantTeamInviteTitle,
                      style: AppTextStyles.h3().copyWith(fontSize: 17),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.md),
                AppInput(
                  label: t.merchantTeamNameLabel,
                  hint: 'Ex: Jean Dupont',
                  controller: nameCtrl,
                  accentColor: AppColors.merchant,
                  prefixIcon: LucideIcons.user,
                ),
                AppInput(
                  label: t.editProfileEmail,
                  hint: 'Ex: jean@lasaveur.tg',
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  accentColor: AppColors.merchant,
                  prefixIcon: LucideIcons.mail,
                ),
                AppInput(
                  label: t.merchantTeamPhoneOptionalLabel,
                  hint: '+228 90 12 34 56',
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  accentColor: AppColors.merchant,
                  prefixIcon: LucideIcons.phone,
                ),
                AppInput(
                  label: t.merchantTeamPasswordLabel,
                  hint: '••••••••',
                  controller: passwordCtrl,
                  obscureText: true,
                  accentColor: AppColors.merchant,
                  prefixIcon: LucideIcons.lock,
                ),
                const SizedBox(height: 4),
                Text(
                  'RÔLE DANS L\'ÉQUIPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(
                          child: Text(t.merchantTeamRoleOperator),
                        ),
                        selected: role == 'operator',
                        selectedColor: AppColors.merchant,
                        backgroundColor: AppColors.isDark ? AppColors.background : AppColors.border,
                        side: BorderSide(
                          color: role == 'operator' ? AppColors.merchant : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: role == 'operator' ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (_) => setSheetState(() => role = 'operator'),
                      ),
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(
                          child: Text(t.merchantTeamRoleAdmin),
                        ),
                        selected: role == 'admin',
                        selectedColor: AppColors.merchant,
                        backgroundColor: AppColors.isDark ? AppColors.background : AppColors.border,
                        side: BorderSide(
                          color: role == 'admin' ? AppColors.merchant : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: role == 'admin' ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (_) => setSheetState(() => role = 'admin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.lg),
                AppButton.merchant(
                  t.merchantTeamInviteButton,
                  loading: saving,
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                      ToastService.showError('Veuillez renseigner le nom et l\'adresse e-mail.');
                      return;
                    }
                    setSheetState(() => saving = true);
                    final notifier = ref.read(teamNotifierProvider.notifier);
                    final ok = await notifier.invite(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          password: passwordCtrl.text.isNotEmpty ? passwordCtrl.text : 'TempPass@123',
                          role: role,
                        );
                    if (!sheetContext.mounted) return;
                    if (ok) {
                      Navigator.pop(sheetContext);
                      ToastService.showSuccess('Membre invité avec succès !');
                    } else {
                      setSheetState(() => saving = false);
                      final message = ErrorTranslator.translate(
                        notifier.lastError,
                        context: ErrorContext.manageTeam,
                      ).displayMessage ??
                          t.merchantTeamInviteError;
                      ToastService.showError(message);
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
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final teamAsync = ref.watch(teamNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher un membre...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : Text(
                t.merchantMoreTeam,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _isSearchOpen ? LucideIcons.arrowLeft : LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () {
            if (_isSearchOpen) {
              setState(() {
                _isSearchOpen = false;
                _searchCtrl.clear();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (_isSearchOpen)
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
              )
            else
              const SizedBox.shrink()
          else ...[
            IconButton(
              icon: Icon(LucideIcons.search, color: AppColors.textPrimary, size: 20),
              tooltip: 'Rechercher',
              onPressed: () => setState(() => _isSearchOpen = true),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.merchant.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.userPlus, color: AppColors.merchant, size: 18),
              ),
              tooltip: t.merchantTeamInviteButton,
              onPressed: () => _showInviteSheet(context),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.merchant)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertCircle, size: 40, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  ErrorTranslator.translate(e, context: ErrorContext.manageTeam)
                          .displayMessage ??
                      t.errUnexpected,
                  style: AppTextStyles.bodyMd(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton.merchant(
                  'Réessayer',
                  onPressed: () => ref.read(teamNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
        data: (team) {
          final query = _searchCtrl.text.trim().toLowerCase();
          final filtered = team.where((m) {
            final matchesQuery = query.isEmpty ||
                m.name.toLowerCase().contains(query) ||
                m.email.toLowerCase().contains(query) ||
                (m.phone?.contains(query) ?? false);
            if (!matchesQuery) return false;
            if (_selectedRoleFilter == 'admin') return m.role == 'admin';
            if (_selectedRoleFilter == 'operator') return m.role == 'operator';
            return true;
          }).toList();

          return Column(
            children: [
              // Filter chips: Tous, Admins, Opérateurs
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.md, 4, Sp.md, Sp.sm),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tous (${team.length})'),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'admin',
                      'Admins (${team.where((m) => m.role == 'admin').length})',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'operator',
                      'Opérateurs (${team.where((m) => m.role == 'operator').length})',
                    ),
                  ],
                ),
              ),

              // Members List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.users, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              t.merchantTeamEmptyState,
                              style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(Sp.md, 4, Sp.md, Sp.lg),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _TeamMemberTile(member: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedRoleFilter == filterKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRoleFilter = filterKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.merchant : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.merchant : AppColors.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
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
    final isAdmin = member.role == 'admin';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isAdmin
                  ? AppColors.merchant.withValues(alpha: 0.12)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              member.initials,
              style: TextStyle(
                color: isAdmin ? AppColors.merchant : const Color(0xFF3B82F6),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.merchant.withValues(alpha: 0.12)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAdmin ? t.merchantTeamRoleAdmin : t.merchantTeamRoleOperator,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isAdmin ? AppColors.merchant : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (member.phone != null && member.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.phone!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status toggle
          Switch(
            value: member.isActive,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.merchant,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) => Colors.transparent),
            onChanged: (val) async {
              final notifier = ref.read(teamNotifierProvider.notifier);
              final ok = await notifier.toggleActive(member.id, val);
              if (!ok && context.mounted) {
                final message = ErrorTranslator.translate(
                  notifier.lastError,
                  context: ErrorContext.manageTeam,
                ).displayMessage ??
                    t.merchantTeamToggleStatusError;
                ToastService.showError(message);
              }
            },
          ),
        ],
      ),
    );
  }
}
