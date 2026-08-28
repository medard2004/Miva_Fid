import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../client/providers/settings_provider.dart';

/// Catégorie visuelle d'une notification — la vraie couleur (fond teinté +
/// icône) n'est résolue qu'au rendu via [NotificationKind.colors], pour
/// rester à jour si le thème change pendant que l'écran est déjà monté.
enum NotificationKind { client, reward, campaign, warning, report, users }

(Color, Color) _kindColors(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.client:
      return (AppColors.primaryTint, const Color(0xFF6366F1));
    case NotificationKind.reward:
      return (AppColors.warningTint, AppColors.warningDark);
    case NotificationKind.campaign:
      return (AppColors.primaryTint, const Color(0xFF0284C7));
    case NotificationKind.warning:
      return (AppColors.dangerTint, AppColors.danger);
    case NotificationKind.report:
      return (AppColors.successTint, const Color(0xFF16A34A));
    case NotificationKind.users:
      return (AppColors.merchantTint, AppColors.merchant);
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String section;
  final IconData icon;
  final NotificationKind kind;
  final bool isUnread;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.section,
    required this.icon,
    required this.kind,
    this.isUnread = false,
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all'; // 'all' | 'unread'

  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      const NotificationItem(
        id: '1',
        title: 'Nouveau client',
        subtitle: 'Ama Doe vient de rejoindre votre programme fidélité.',
        time: 'il y a 5 min',
        section: "AUJOURD'HUI",
        icon: LucideIcons.userPlus,
        kind: NotificationKind.client,
        isUnread: true,
      ),
      const NotificationItem(
        id: '2',
        title: 'Récompense débloquée',
        subtitle: 'Kofi M. a atteint 10 tampons — offrez son cadeau 🎁',
        time: 'il y a 32 min',
        section: "AUJOURD'HUI",
        icon: LucideIcons.gift,
        kind: NotificationKind.reward,
        isUnread: true,
      ),
      const NotificationItem(
        id: '3',
        title: 'Campagne envoyée',
        subtitle: '« Weekend -20% » livrée à 128 clients (98% de succès).',
        time: 'il y a 2 h',
        section: "AUJOURD'HUI",
        icon: LucideIcons.messageSquare,
        kind: NotificationKind.campaign,
        isUnread: true,
      ),
      const NotificationItem(
        id: '4',
        title: 'Quota SMS faible',
        subtitle: 'Il vous reste 13 SMS ce mois-ci. Rechargez pour continuer.',
        time: 'hier',
        section: 'CETTE SEMAINE',
        icon: LucideIcons.triangleAlert,
        kind: NotificationKind.warning,
        isUnread: false,
      ),
      const NotificationItem(
        id: '5',
        title: 'Rapport hebdomadaire',
        subtitle: '+42 nouveaux clients cette semaine — un record !',
        time: 'lun.',
        section: 'CETTE SEMAINE',
        icon: LucideIcons.trendingUp,
        kind: NotificationKind.report,
        isUnread: false,
      ),
      const NotificationItem(
        id: '6',
        title: '5 nouveaux clients',
        subtitle: 'Vos QR codes en boutique ont bien fonctionné hier.',
        time: 'il y a 8 j',
        section: 'PLUS ANCIEN',
        icon: LucideIcons.users,
        kind: NotificationKind.users,
        isUnread: false,
      ),
    ];
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications.map((n) {
        return NotificationItem(
          id: n.id,
          title: n.title,
          subtitle: n.subtitle,
          time: n.time,
          section: n.section,
          icon: n.icon,
          kind: n.kind,
          isUnread: false,
        );
      }).toList();
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final unreadCount = _notifications.where((n) => n.isUnread).length;

    final filtered = _selectedFilter == 'unread'
        ? _notifications.where((n) => n.isUnread).toList()
        : _notifications;

    final sections = <String, List<NotificationItem>>{};
    for (final item in filtered) {
      sections.putIfAbsent(item.section, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$unreadCount non lues',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.settings, color: AppColors.textSecondary, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
              context.go('/merchant/more');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── FILTER TABS ROW ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Toutes',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Non lues',
                  count: unreadCount,
                  isSelected: _selectedFilter == 'unread',
                  onTap: () => setState(() => _selectedFilter = 'unread'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: unreadCount > 0 ? _markAllRead : null,
                  icon: const Icon(LucideIcons.check, size: 16, color: Color(0xFF6366F1)),
                  label: const Text(
                    'Tout lire',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── LIST OF NOTIFICATIONS BY SECTION ──
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Text(
                      'Aucune notification',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      for (final section in sections.keys) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                          child: Text(
                            section,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < sections[section]!.length; i++) ...[
                                _buildNotificationTile(sections[section]![i]),
                                if (i < sections[section]!.length - 1)
                                  Divider(height: 1, indent: 64, color: AppColors.border),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      if (_notifications.isNotEmpty)
                        Center(
                          child: TextButton.icon(
                            onPressed: _clearAll,
                            icon: Icon(LucideIcons.trash2, size: 16, color: AppColors.textSecondary),
                            label: Text(
                              'Effacer toutes les notifications',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    final (iconBg, iconColor) = _kindColors(item.kind);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (item.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
