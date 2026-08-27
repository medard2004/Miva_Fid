import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../client/providers/settings_provider.dart';

/// Traduit un code de palier interne ('Argent'/'Or'/'Platine', utilisé comme
/// valeur de données/filtre) vers son libellé localisé affiché à l'écran.
String _tierLabel(AppLocalizations t, String tier) {
  switch (tier) {
    case 'Argent':
      return t.merchantTierSilver;
    case 'Or':
      return t.merchantTierGold;
    case 'Platine':
      return t.merchantTierPlatinum;
    default:
      return tier;
  }
}

class _ClientMock {
  final String id;
  final String initials;
  final Color avatarColor;
  final String name;
  final String tier;
  final Color tierBgColor;
  final Color tierTextColor;
  final String phone;
  final String lastActivity;
  final int currentStamps;
  final int totalStamps;

  const _ClientMock({
    required this.id,
    required this.initials,
    required this.avatarColor,
    required this.name,
    required this.tier,
    required this.tierBgColor,
    required this.tierTextColor,
    required this.phone,
    required this.lastActivity,
    required this.currentStamps,
    this.totalStamps = 10,
  });
}

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _selectedFilter = 'Tous';
  final _searchCtrl = TextEditingController();

  static List<_ClientMock> get _mockClients => [
    _ClientMock(
      id: '1',
      initials: 'AM',
      avatarColor: const Color(0xFF6366F1),
      name: 'Afi Mensah',
      tier: 'Or',
      tierBgColor: AppColors.warningTint,
      tierTextColor: AppColors.warningDark,
      phone: '+228 90 12 34 56',
      lastActivity: 'Il y a 2h',
      currentStamps: 7,
    ),
    _ClientMock(
      id: '2',
      initials: 'KA',
      avatarColor: const Color(0xFF6366F1),
      name: 'Kofi Agbeko',
      tier: 'Argent',
      tierBgColor: AppColors.border,
      tierTextColor: AppColors.textSecondary,
      phone: '+228 91 23 45 67',
      lastActivity: 'Il y a 3h',
      currentStamps: 3,
    ),
    _ClientMock(
      id: '3',
      initials: 'MD',
      avatarColor: const Color(0xFF6366F1),
      name: 'Mawuli Dossou',
      tier: 'Platine',
      tierBgColor: AppColors.merchantTint,
      tierTextColor: AppColors.merchant,
      phone: '+228 92 34 56 78',
      lastActivity: 'Hier',
      currentStamps: 10,
    ),
    _ClientMock(
      id: '4',
      initials: 'AT',
      avatarColor: const Color(0xFF6366F1),
      name: 'Akosua Tetteh',
      tier: 'Argent',
      tierBgColor: AppColors.border,
      tierTextColor: AppColors.textSecondary,
      phone: '+228 93 45 67 89',
      lastActivity: 'Hier',
      currentStamps: 5,
    ),
    _ClientMock(
      id: '5',
      initials: 'YK',
      avatarColor: const Color(0xFFF59E0B),
      name: 'Yawa Kpodo',
      tier: 'Or',
      tierBgColor: AppColors.warningTint,
      tierTextColor: AppColors.warningDark,
      phone: '+228 94 56 78 90',
      lastActivity: 'Il y a 2j',
      currentStamps: 8,
    ),
    _ClientMock(
      id: '6',
      initials: 'KA',
      avatarColor: const Color(0xFFF59E0B),
      name: 'Komi Adjovi',
      tier: 'Argent',
      tierBgColor: AppColors.border,
      tierTextColor: AppColors.textSecondary,
      phone: '+228 95 67 89 01',
      lastActivity: 'Il y a 4j',
      currentStamps: 2,
    ),
    _ClientMock(
      id: '7',
      initials: 'AS',
      avatarColor: const Color(0xFF06B6D4),
      name: 'Ama Sossou',
      tier: 'Or',
      tierBgColor: AppColors.warningTint,
      tierTextColor: AppColors.warningDark,
      phone: '+228 96 78 90 12',
      lastActivity: 'Il y a 5j',
      currentStamps: 6,
    ),
    _ClientMock(
      id: '8',
      initials: 'SA',
      avatarColor: const Color(0xFF6366F1),
      name: 'Sena Akakpo',
      tier: 'Platine',
      tierBgColor: AppColors.merchantTint,
      tierTextColor: AppColors.merchant,
      phone: '+228 97 89 01 23',
      lastActivity: 'Il y a 6j',
      currentStamps: 9,
    ),
    _ClientMock(
      id: '9',
      initials: 'EK',
      avatarColor: const Color(0xFF10B981),
      name: 'Edem Kuevi',
      tier: 'Argent',
      tierBgColor: AppColors.border,
      tierTextColor: AppColors.textSecondary,
      phone: '+228 98 90 12 34',
      lastActivity: 'Il y a 8j',
      currentStamps: 4,
    ),
    _ClientMock(
      id: '10',
      initials: 'FL',
      avatarColor: const Color(0xFF6366F1),
      name: 'Fafa Lawson',
      tier: 'Or',
      tierBgColor: AppColors.warningTint,
      tierTextColor: AppColors.warningDark,
      phone: '+228 99 01 23 45',
      lastActivity: 'Il y a 10j',
      currentStamps: 7,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_ClientMock> get _filteredClients {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _mockClients.where((c) {
      final matchesQuery = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.phone.contains(query);
      if (!matchesQuery) return false;
      if (_selectedFilter == 'Tous') return true;
      if (_selectedFilter == 'Argent') return c.tier == 'Argent';
      if (_selectedFilter == 'Or') return c.tier == 'Or';
      if (_selectedFilter == 'Platine') return c.tier == 'Platine';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final clients = _filteredClients;

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
                      color: Color(0xFF5B50EC),
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
                          t.merchantClientsActiveCount('10'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => ToastService.showSuccess(
                        t.merchantClientsAddSoonToast),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B50EC),
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

            // ── EXPORTER LA LISTE BUTTON ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => ToastService.showSuccess(
                    t.merchantClientsExportToast),
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

            // ── SEARCH BAR ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: t.merchantClientsSearchHint,
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── FILTER PILLS ─────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Tous', 'Argent', 'Or', 'Platine', '+30j'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.surface : AppColors.border,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: AppColors.textPrimary, width: 1.2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            if (filter == 'Tous') ...[
                              Icon(
                                LucideIcons.alignLeft,
                                size: 12,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              filter == 'Tous'
                                  ? t.merchantClientsFilterAll
                                  : filter == '+30j'
                                      ? t.merchantClientsFilterInactive30d
                                      : _tierLabel(t, filter),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // ── CLIENTS LIST ─────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: clients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return _ClientCard(
                    client: client,
                    onTap: () => context.push('/merchant/clients/${client.id}'),
                    onSms: () => context.push('/merchant/sms/conversation'),
                  );
                },
              ),
            ),

            // ── PAGINATION FOOTER ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.merchantClientsPaginationInfo('1', '10', '10'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        t.merchantClientsPrevious,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          t.merchantClientsNext,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onSms,
  });

  final _ClientMock client;
  final VoidCallback onTap;
  final VoidCallback onSms;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final progressFactor = (client.currentStamps / client.totalStamps).clamp(0.0, 1.0);

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
                    color: client.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      client.initials,
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
                              client.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: client.tierBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _tierLabel(t, client.tier),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: client.tierTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${client.phone} • ${client.lastActivity}',
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
                        child: Container(color: const Color(0xFF5B50EC)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${client.currentStamps}/${client.totalStamps}',
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
