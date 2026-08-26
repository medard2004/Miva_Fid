import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/toast_service.dart';
import '../../client/providers/settings_provider.dart';

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

  static const _mockClients = [
    _ClientMock(
      id: '1',
      initials: 'AM',
      avatarColor: Color(0xFF6366F1),
      name: 'Afi Mensah',
      tier: 'Or',
      tierBgColor: Color(0xFFFEF3C7),
      tierTextColor: Color(0xFFD97706),
      phone: '+228 90 12 34 56',
      lastActivity: 'Il y a 2h',
      currentStamps: 7,
    ),
    _ClientMock(
      id: '2',
      initials: 'KA',
      avatarColor: Color(0xFF6366F1),
      name: 'Kofi Agbeko',
      tier: 'Argent',
      tierBgColor: Color(0xFFF1F5F9),
      tierTextColor: Color(0xFF64748B),
      phone: '+228 91 23 45 67',
      lastActivity: 'Il y a 3h',
      currentStamps: 3,
    ),
    _ClientMock(
      id: '3',
      initials: 'MD',
      avatarColor: Color(0xFF6366F1),
      name: 'Mawuli Dossou',
      tier: 'Platine',
      tierBgColor: Color(0xFFF3E8FF),
      tierTextColor: Color(0xFF9333EA),
      phone: '+228 92 34 56 78',
      lastActivity: 'Hier',
      currentStamps: 10,
    ),
    _ClientMock(
      id: '4',
      initials: 'AT',
      avatarColor: Color(0xFF6366F1),
      name: 'Akosua Tetteh',
      tier: 'Argent',
      tierBgColor: Color(0xFFF1F5F9),
      tierTextColor: Color(0xFF64748B),
      phone: '+228 93 45 67 89',
      lastActivity: 'Hier',
      currentStamps: 5,
    ),
    _ClientMock(
      id: '5',
      initials: 'YK',
      avatarColor: Color(0xFFF59E0B),
      name: 'Yawa Kpodo',
      tier: 'Or',
      tierBgColor: Color(0xFFFEF3C7),
      tierTextColor: Color(0xFFD97706),
      phone: '+228 94 56 78 90',
      lastActivity: 'Il y a 2j',
      currentStamps: 8,
    ),
    _ClientMock(
      id: '6',
      initials: 'KA',
      avatarColor: Color(0xFFF59E0B),
      name: 'Komi Adjovi',
      tier: 'Argent',
      tierBgColor: Color(0xFFF1F5F9),
      tierTextColor: Color(0xFF64748B),
      phone: '+228 95 67 89 01',
      lastActivity: 'Il y a 4j',
      currentStamps: 2,
    ),
    _ClientMock(
      id: '7',
      initials: 'AS',
      avatarColor: Color(0xFF06B6D4),
      name: 'Ama Sossou',
      tier: 'Or',
      tierBgColor: Color(0xFFFEF3C7),
      tierTextColor: Color(0xFFD97706),
      phone: '+228 96 78 90 12',
      lastActivity: 'Il y a 5j',
      currentStamps: 6,
    ),
    _ClientMock(
      id: '8',
      initials: 'SA',
      avatarColor: Color(0xFF6366F1),
      name: 'Sena Akakpo',
      tier: 'Platine',
      tierBgColor: Color(0xFFF3E8FF),
      tierTextColor: Color(0xFF9333EA),
      phone: '+228 97 89 01 23',
      lastActivity: 'Il y a 6j',
      currentStamps: 9,
    ),
    _ClientMock(
      id: '9',
      initials: 'EK',
      avatarColor: Color(0xFF10B981),
      name: 'Edem Kuevi',
      tier: 'Argent',
      tierBgColor: Color(0xFFF1F5F9),
      tierTextColor: Color(0xFF64748B),
      phone: '+228 98 90 12 34',
      lastActivity: 'Il y a 8j',
      currentStamps: 4,
    ),
    _ClientMock(
      id: '10',
      initials: 'FL',
      avatarColor: Color(0xFF6366F1),
      name: 'Fafa Lawson',
      tier: 'Or',
      tierBgColor: Color(0xFFFEF3C7),
      tierTextColor: Color(0xFFD97706),
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
    final clients = _filteredClients;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
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
                      color: const Color(0xFFEEF2FF),
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
                      children: const [
                        Text(
                          'Mes clients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '10 clients actifs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => ToastService.showSuccess(
                        'Ajout manuel d\'un client bientôt disponible.'),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            LucideIcons.bell,
                            size: 18,
                            color: Color(0xFF1E293B),
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
                    'Exportation de la liste clients au format CSV lancée !'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        LucideIcons.download,
                        size: 16,
                        color: Color(0xFF1E293B),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Exporter la liste',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Rechercher un client...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: const Color(0xFF1E293B), width: 1.2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            if (filter == 'Tous') ...[
                              Icon(
                                LucideIcons.alignLeft,
                                size: 12,
                                color: isSelected
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF64748B),
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
                    onSms: () => context.push('/merchant/sms'),
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
                  const Text(
                    '1-10 sur 10',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        '< Préc.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Text(
                          'Suiv. >',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E293B),
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
    final progressFactor = (client.currentStamps / client.totalStamps).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDF0F7)),
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
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
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
                              client.tier,
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
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
                      color: const Color(0xFFF8F9FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      LucideIcons.eye,
                      size: 14,
                      color: Color(0xFF64748B),
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
                      color: const Color(0xFFF8F9FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: Color(0xFF64748B),
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
                      color: const Color(0xFFF1F5F9),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
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
