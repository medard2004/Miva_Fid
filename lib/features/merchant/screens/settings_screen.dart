import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/merchant_model.dart';
import '../providers/merchant_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _activeTabIndex = 0;
  int _prevTabIndex = 0;
  bool _initialized = false;

  // Form Profile Controllers
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  String _selectedLanguage = 'Français';
  bool _isSavingProfile = false;

  // Plan update state
  bool _isUpdatingPlan = false;

  // Local state for notification switches
  bool _notifNewClient = true;
  bool _notifReward = true;
  bool _notifLowSms = true;
  bool _notifWeeklyReport = false;
  bool _notifPromotions = false;

  // Team list state
  final GlobalKey<AnimatedListState> _teamListKey = GlobalKey<AnimatedListState>();
  final List<Map<String, String>> _teamMembers = [
    {'name': 'Kofi Mensah', 'role': 'Propriétaire', 'status': 'Actif', 'initials': 'KM'},
    {'name': 'Ama Doe', 'role': 'Caissière', 'status': 'Actif', 'initials': 'AD'},
    {'name': 'Yao Lawson', 'role': 'Serveur', 'status': 'Invité', 'initials': 'YL'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(merchantNotifierProvider).value;

    if (merchant != null && !_initialized) {
      _nameController.text = merchant.name;
      _phoneController.text = merchant.phone ?? '';
      _emailController.text = Supabase.instance.client.auth.currentUser?.email ?? 'contact@lasaveur.tg';
      _initialized = true;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 768;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Master Panel)
              SizedBox(
                width: 340,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Paramètres',
                        style: AppTextStyles.h1().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: Sp.md),
                      _buildMerchantHeaderCard(merchant),
                      const SizedBox(height: Sp.md),
                      _buildVerticalTabs(),
                      const SizedBox(height: Sp.md),
                      _buildCommonSettingsCard(context),
                      const SizedBox(height: Sp.md),
                      Center(
                        child: Text(
                          'Miva-Fid v1.0.0 • Lomé, Togo',
                          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: AppColors.border, thickness: 1),
              // Right Column (Details Panel)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _getTabTitle(_activeTabIndex),
                        style: AppTextStyles.h2().copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: Sp.md),
                      _buildTabContentWithAnimation(merchant),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Narrow layout (Mobile)
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paramètres',
              style: AppTextStyles.h1().copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Sp.md),
            _buildMerchantHeaderCard(merchant),
            const SizedBox(height: Sp.md),
            _buildHorizontalTabs(),
            const SizedBox(height: Sp.md),
            _buildTabContentWithAnimation(merchant),
            const SizedBox(height: Sp.md),
            _buildCommonSettingsCard(context),
            const SizedBox(height: Sp.md),
            Center(
              child: Text(
                'Miva-Fid v1.0.0 • Lomé, Togo',
                style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: Sp.xl),
          ],
        ),
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Mon profil';
      case 1:
        return 'Mon abonnement';
      case 2:
        return 'Préférences de notifications';
      case 3:
        return 'Membres de l\'équipe';
      default:
        return 'Paramètres';
    }
  }

  Widget _buildMerchantHeaderCard(MerchantModel? merchant) {
    final initials = merchant?.initials ?? 'LS';
    final name = merchant?.name ?? 'Restaurant La Saveur';
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'contact@lasaveur.tg';

    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: AppTextStyles.bodyMd().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelBold().copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTabItem(0, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
          const SizedBox(width: Sp.sm),
          _buildTabItem(1, Icons.credit_card_outlined, Icons.credit_card_rounded, 'Abonnement'),
          const SizedBox(width: Sp.sm),
          _buildTabItem(2, Icons.notifications_none_rounded, Icons.notifications_rounded, 'Notifs'),
          const SizedBox(width: Sp.sm),
          _buildTabItem(3, Icons.people_outline_rounded, Icons.people_rounded, 'Équipe'),
        ],
      ),
    );
  }

  Widget _buildVerticalTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabItem(0, Icons.person_outline_rounded, Icons.person_rounded, 'Profil', isVertical: true),
        const SizedBox(height: Sp.sm),
        _buildTabItem(1, Icons.credit_card_outlined, Icons.credit_card_rounded, 'Abonnement', isVertical: true),
        const SizedBox(height: Sp.sm),
        _buildTabItem(2, Icons.notifications_none_rounded, Icons.notifications_rounded, 'Notifs', isVertical: true),
        const SizedBox(height: Sp.sm),
        _buildTabItem(3, Icons.people_outline_rounded, Icons.people_rounded, 'Équipe', isVertical: true),
      ],
    );
  }

  Widget _buildTabItem(int index, IconData icon, IconData activeIcon, String label, {bool isVertical = false}) {
    final bool isActive = _activeTabIndex == index;
    final Color bg = isActive ? AppColors.merchant : Colors.white;
    final Color fg = isActive ? Colors.white : AppColors.textPrimary;
    final Color border = isActive ? AppColors.merchant : AppColors.border;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(color: border, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (_activeTabIndex == index) return;
          setState(() {
            _prevTabIndex = _activeTabIndex;
            _activeTabIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 10),
          child: Row(
            mainAxisSize: isVertical ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: isVertical ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(isActive ? activeIcon : icon, color: fg, size: 18),
              const SizedBox(width: Sp.sm),
              Text(
                label,
                style: AppTextStyles.labelBold().copyWith(
                  color: fg,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContentWithAnimation(MerchantModel? merchant) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isEntering = child.key == ValueKey<int>(_activeTabIndex);
          final double slideOffset = _activeTabIndex > _prevTabIndex ? 0.15 : -0.15;

          final Animation<Offset> offsetAnimation = Tween<Offset>(
            begin: Offset(isEntering ? slideOffset : -slideOffset, 0.0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_activeTabIndex),
          child: _buildTabContent(_activeTabIndex, merchant),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index, MerchantModel? merchant) {
    switch (index) {
      case 0:
        return _buildProfileTab(merchant);
      case 1:
        return _buildAbonnementTab(merchant);
      case 2:
        return _buildNotifsTab();
      case 3:
        return _buildTeamTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileTab(MerchantModel? merchant) {
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputLabel('NOM DU COMMERCE'),
            const SizedBox(height: Sp.xs),
            TextFormField(
              controller: _nameController,
              style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                fillColor: AppColors.bgLight,
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: Rd.input,
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: Sp.md),
            _buildInputLabel('EMAIL'),
            const SizedBox(height: Sp.xs),
            TextFormField(
              controller: _emailController,
              enabled: false,
              style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
              decoration: InputDecoration(
                fillColor: AppColors.bgLight.withValues(alpha: 0.5),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                border: const OutlineInputBorder(
                  borderRadius: Rd.input,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: Sp.md),
            _buildInputLabel('TÉLÉPHONE'),
            const SizedBox(height: Sp.xs),
            TextFormField(
              controller: _phoneController,
              style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                fillColor: AppColors.bgLight,
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: Rd.input,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: Sp.md),
            _buildInputLabel('LANGUE'),
            const SizedBox(height: Sp.xs),
            DropdownButtonFormField<String>(
              initialValue: _selectedLanguage,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                fillColor: AppColors.bgLight,
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: Rd.input,
                  borderSide: BorderSide.none,
                ),
              ),
              items: ['Français', 'English'].map((lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLanguage = val);
                }
              },
            ),
            const SizedBox(height: Sp.lg),
            AppButton.merchant(
              'Enregistrer',
              loading: _isSavingProfile,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() => _isSavingProfile = true);
                try {
                  await ref.read(merchantNotifierProvider.notifier).updateProgramme({
                    'name': _nameController.text.trim(),
                    'phone': _phoneController.text.trim(),
                  });
                  _initialized = false;
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil mis à jour avec succès'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la mise à jour : $e'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSavingProfile = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.caption().copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAbonnementTab(MerchantModel? merchant) {
    final currentPlan = merchant?.plan ?? 'free';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPlanCard(
          title: 'Démarrage',
          price: '0 F/mois',
          details: '50 clients • 30 SMS',
          planKey: 'free',
          currentPlan: currentPlan,
        ),
        const SizedBox(height: Sp.sm),
        _buildPlanCard(
          title: 'Pro',
          price: '9 900 F/mois',
          details: '500 clients • 100 SMS',
          planKey: 'pro',
          currentPlan: currentPlan,
        ),
        const SizedBox(height: Sp.sm),
        _buildPlanCard(
          title: 'Business',
          price: '24 900 F/mois',
          details: 'Illimité • 500 SMS',
          planKey: 'business',
          currentPlan: currentPlan,
        ),
        const SizedBox(height: Sp.md),
        Container(
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Rd.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prochaine facture',
                    style: AppTextStyles.labelBold().copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '15 janvier 2026',
                    style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                currentPlan == 'business'
                    ? '24 900 F'
                    : currentPlan == 'pro'
                        ? '9 900 F'
                        : '0 F',
                style: AppTextStyles.mono().copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String details,
    required String planKey,
    required String currentPlan,
  }) {
    final bool isCurrent = planKey == currentPlan;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        border: Border.all(
          color: isCurrent ? AppColors.merchant : AppColors.border,
          width: isCurrent ? 2.0 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.merchant.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3().copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: Sp.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.merchant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTUEL',
                          style: AppTextStyles.caption().copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Sp.xs),
                Text(
                  details,
                  style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: AppTextStyles.mono().copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!isCurrent) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: _isUpdatingPlan
                      ? null
                      : () async {
                          setState(() => _isUpdatingPlan = true);
                          try {
                            await ref.read(merchantNotifierProvider.notifier).updateProgramme({'plan': planKey});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Abonnement modifié : plan $title sélectionné'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur lors du changement de plan : $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isUpdatingPlan = false);
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Choisir',
                      style: AppTextStyles.labelBold().copyWith(
                        color: AppColors.merchant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotifsTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildNotifSwitch(
            title: 'Nouveau client',
            subtitle: 'Notif. à chaque inscription',
            value: _notifNewClient,
            onChanged: (val) => setState(() => _notifNewClient = val),
          ),
          const Divider(height: 0, indent: Sp.md),
          _buildNotifSwitch(
            title: 'Récompense gagnée',
            subtitle: 'Quand un palier est atteint',
            value: _notifReward,
            onChanged: (val) => setState(() => _notifReward = val),
          ),
          const Divider(height: 0, indent: Sp.md),
          _buildNotifSwitch(
            title: 'Quota SMS faible',
            subtitle: 'Sous 20 SMS restants',
            value: _notifLowSms,
            onChanged: (val) => setState(() => _notifLowSms = val),
          ),
          const Divider(height: 0, indent: Sp.md),
          _buildNotifSwitch(
            title: 'Rapport hebdomadaire',
            subtitle: 'Tous les lundis matin',
            value: _notifWeeklyReport,
            onChanged: (val) => setState(() => _notifWeeklyReport = val),
          ),
          const Divider(height: 0, indent: Sp.md),
          _buildNotifSwitch(
            title: 'Promotions Miva-Fid',
            subtitle: 'Offres et nouveautés',
            value: _notifPromotions,
            onChanged: (val) => setState(() => _notifPromotions = val),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
      title: Text(
        title,
        style: AppTextStyles.bodyMd().copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.merchant,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.border,
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
          return Colors.transparent;
        }),
      ),
    );
  }

  Widget _buildTeamTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Rd.card,
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedList(
            key: _teamListKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: _teamMembers.length,
            itemBuilder: (context, index, animation) {
              return _buildTeamMemberItem(_teamMembers[index], animation, index);
            },
          ),
        ),
        const SizedBox(height: Sp.md),
        _buildInviteMemberButton(),
      ],
    );
  }

  Widget _buildTeamMemberItem(Map<String, String> member, Animation<double> animation, int index) {
    final initials = member['initials'] ?? 'KM';
    final name = member['name'] ?? '';
    final role = member['role'] ?? '';
    final status = member['status'] ?? '';
    final isActif = status == 'Actif';

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.merchantTint,
                    child: Text(
                      initials,
                      style: AppTextStyles.bodyMd().copyWith(
                        color: AppColors.merchant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role,
                          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActif ? AppColors.successTint : AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActif) ...[
                          const Icon(Icons.check_rounded, color: AppColors.success, size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          status,
                          style: AppTextStyles.caption().copyWith(
                            color: isActif ? AppColors.success : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                    onPressed: () => _removeTeamMember(index),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            if (index < _teamMembers.length - 1)
              const Divider(height: 0, indent: 56),
          ],
        ),
      ),
    );
  }

  void _removeTeamMember(int index) {
    if (index < 0 || index >= _teamMembers.length) return;

    final removedItem = _teamMembers[index];

    setState(() {
      _teamMembers.removeAt(index);
    });

    _teamListKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTeamMemberItem(removedItem, animation, index),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildInviteMemberButton() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: AppColors.merchant.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        dashLength: 6.0,
        gap: 4.0,
      ),
      child: InkWell(
        onTap: _showInviteMemberDialog,
        borderRadius: Rd.card,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: Sp.md),
          alignment: Alignment.center,
          child: Text(
            '+ Inviter un membre',
            style: AppTextStyles.labelBold().copyWith(
              color: AppColors.merchant,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteMemberDialog() {
    final nameController = TextEditingController();
    String selectedRole = 'Serveur';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: Rd.card),
              title: Text(
                'Inviter un membre d\'équipe',
                style: AppTextStyles.h3().copyWith(color: AppColors.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputLabel('NOM COMPLET'),
                  const SizedBox(height: Sp.xs),
                  TextField(
                    controller: nameController,
                    style: AppTextStyles.bodyMd(),
                    decoration: const InputDecoration(
                      fillColor: AppColors.bgLight,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: Rd.input,
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Ex: Yao Lawson',
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                  _buildInputLabel('RÔLE'),
                  const SizedBox(height: Sp.xs),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      fillColor: AppColors.bgLight,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: Sp.md, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: Rd.input,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ['Propriétaire', 'Caissière', 'Serveur'].map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(context);
                    _addTeamMember(name, selectedRole);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchant,
                    shape: const RoundedRectangleBorder(borderRadius: Rd.button),
                  ),
                  child: const Text('Inviter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addTeamMember(String name, String role) {
    final parts = name.split(' ');
    String initials = '?';
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name[0].toUpperCase();
    }

    final newMember = {
      'name': name,
      'role': role,
      'status': 'Invité',
      'initials': initials,
    };

    final int newIndex = _teamMembers.length;
    setState(() {
      _teamMembers.add(newMember);
    });

    _teamListKey.currentState?.insertItem(
      newIndex,
      duration: const Duration(milliseconds: 300),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name a été invité(e) en tant que $role'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildCommonSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildCommonTile(
            icon: Icons.shield_outlined,
            label: 'Sécurité & confidentialité',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sécurité & confidentialité bientôt disponible')),
              );
            },
          ),
          const Divider(height: 0, indent: Sp.md),
          _buildCommonTile(
            icon: Icons.help_outline_rounded,
            label: 'Aide & support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Centre d\'aide bientôt disponible')),
              );
            },
          ),
          const Divider(height: 0, indent: Sp.md),
          _buildCommonTile(
            icon: Icons.logout_rounded,
            label: 'Se déconnecter',
            textColor: AppColors.danger,
            iconColor: AppColors.danger,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/role-select');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommonTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      title: Text(
        label,
        style: AppTextStyles.bodyMd().copyWith(
          color: textColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: textColor ?? AppColors.textSecondary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 2),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    final PathMetrics pathMetrics = path.computeMetrics();
    for (final PathMetric metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = dashLength;
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
